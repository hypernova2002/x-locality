# frozen_string_literal: true

module Backend
  module Translations
    class Create < Backend::Operation
      TranslationOutcome = Struct.new(:status, :translated_text, :detected_language, :cached, keyword_init: true)

      def call(project:, target_locale_keys:, items:, unit_limit:, force: false)
        step check_llm_configured(project)
        step check_unit_limit(items.size * target_locale_keys.size, unit_limit)
        step check_budget(project)

        locales = load_locales(project, target_locale_keys)
        step check_all_locales_found(locales, target_locale_keys)

        context_tags_by_key = load_context_tags(project, items)
        step check_all_context_tags_found(context_tags_by_key, items)

        glossary_terms = load_glossary_terms(project, items)

        results = target_locale_keys.to_h do |locale_key|
          [locale_key, translate_for_locale(project, locales[locale_key], items, context_tags_by_key,
            glossary_terms, force)]
        end

        notify_translation_webhooks(project, target_locale_keys, results)

        build_response(items, target_locale_keys, results)
      end

      private

      def check_llm_configured(project)
        unless project.llm_config&.active_llm_provider_config&.api_key_configured?
          return Failure([:unconfigured,
            "This project has no LLM provider configured - set a provider/API key in its LLM settings first"])
        end

        Success(true)
      end

      def check_unit_limit(unit_count, limit)
        if unit_count > limit
          return Failure([:validation,
            "#{unit_count} translation units (items x locales) exceeds the synchronous limit of #{limit}"])
        end

        Success(true)
      end

      def check_budget(project)
        config = project.llm_config
        return Success(true) if config.monthly_cost_limit_usd.nil? && config.monthly_token_limit.nil?

        start_of_month = Date.new(Date.today.year, Date.today.month, 1)
        events = Backend::Models::LlmUsageEvent
          .where(project_id: project.id, success: true)
          .where { created_at >= start_of_month }
          .all

        tokens_used = events.sum { |e| e.input_tokens + e.output_tokens }
        cost_used = events.filter_map do |e|
          Backend::Llm::Pricing.cost(model: e.llm_model, input_tokens: e.input_tokens, output_tokens: e.output_tokens)
        end.sum

        maybe_send_budget_alert(project, config, tokens_used: tokens_used, cost_used: cost_used)

        if config.monthly_token_limit && tokens_used >= config.monthly_token_limit
          return Failure([:budget_exceeded,
            "Monthly token limit (#{config.monthly_token_limit}) reached (#{tokens_used} used this month)"])
        end

        if config.monthly_cost_limit_usd && cost_used >= config.monthly_cost_limit_usd.to_f
          return Failure([:budget_exceeded,
            "Monthly cost limit ($#{config.monthly_cost_limit_usd}) reached ($#{format('%.2f', cost_used)} used this month)"])
        end

        Success(true)
      end

      # Fires at most once per calendar month, the first time either limit's
      # usage crosses the configured warning threshold - independent of
      # (and ahead of) the hard :budget_exceeded block above.
      def maybe_send_budget_alert(project, config, tokens_used:, cost_used:)
        return unless config.alert_email && config.alert_threshold_percent

        current_month = Date.today.strftime("%Y-%m")
        return if config.alert_sent_for_month == current_month

        token_pct = config.monthly_token_limit ? (tokens_used.to_f / config.monthly_token_limit * 100) : 0
        cost_pct = config.monthly_cost_limit_usd ? (cost_used / config.monthly_cost_limit_usd.to_f * 100) : 0
        return unless token_pct >= config.alert_threshold_percent || cost_pct >= config.alert_threshold_percent

        config.update(alert_sent_for_month: current_month)
        Backend::LlmConfigs::Jobs::SendBudgetAlertJob.perform_async(project.id, tokens_used, cost_used)
        Backend::ProjectWebhooks::Notify.new.call(
          project: project, event_type: "budget.threshold_crossed",
          payload: {
            "tokens_used" => tokens_used, "cost_used" => cost_used,
            "threshold_percent" => config.alert_threshold_percent
          }
        )
      end

      # Fired once per Create call (not per translation) - one item x
      # locale batch is the natural unit of "translation activity happened"
      # for a webhook subscriber, whether triggered externally or via an
      # admin regenerate/bulk_regenerate.
      def notify_translation_webhooks(project, target_locale_keys, results)
        completed = results.values.sum { |outcomes| outcomes.values.count { |o| o.status == "completed" } }
        failed = results.values.sum { |outcomes| outcomes.values.count { |o| o.status == "failed" } }

        Backend::ProjectWebhooks::Notify.new.call(
          project: project, event_type: "translation.batch_completed",
          payload: {
            "target_locales" => target_locale_keys, "completed" => completed, "failed" => failed
          }
        )
      end

      def load_locales(project, keys)
        project.locales_dataset.where(key: keys).all.to_h { |l| [l.key, l] }
      end

      def check_all_locales_found(locales, keys)
        missing = keys - locales.keys
        return Failure([:validation, "Unknown target locale(s): #{missing.join(', ')}"]) unless missing.empty?

        Success(true)
      end

      def load_context_tags(project, items)
        keys = items.flat_map { |i| i[:context] || [] }.uniq
        return {} if keys.empty?

        project.context_tags_dataset.where(key: keys).all.to_h { |t| [t.key, t] }
      end

      def check_all_context_tags_found(context_tags_by_key, items)
        unknown = items.flat_map { |i| i[:context] || [] }.uniq - context_tags_by_key.keys
        return Failure([:validation, "Unknown context tag(s): #{unknown.join(', ')}"]) unless unknown.empty?

        Success(true)
      end

      # Loaded once per call (not per item) - matching against source_text
      # happens later, per item/locale, in matching_glossary_terms.
      def load_glossary_terms(project, items)
        languages = items.filter_map { |i| i[:source_language] }.uniq
        return [] if languages.empty?

        project.glossary_terms_dataset.where(source_language: languages).all
      end

      # Plain case-insensitive substring match, deliberately not
      # word-boundary-anchored - many source languages (Japanese, Chinese,
      # Thai) have no whitespace between words, so a boundary-anchored regex
      # would silently fail to match exactly the languages where getting
      # this right matters most. The prompt phrases each match as
      # conditional ("if relevant"), so an occasional over-match is
      # harmless - the LLM just ignores it if it doesn't apply.
      def matching_glossary_terms(glossary_terms, item, locale)
        return [] if item[:source_language].nil? || item[:source_text].nil?

        source_text = item[:source_text].downcase
        glossary_terms.select do |term|
          term.source_language == item[:source_language] &&
            (term.target_locale_id.nil? || term.target_locale_id == locale.id) &&
            source_text.include?(term.source_term.downcase)
        end
      end

      def translate_for_locale(project, locale, items, context_tags_by_key, glossary_terms, force)
        existing = project.translations_dataset
          .where(locale_id: locale.id, key: items.map { |i| i[:key] })
          .all.to_h { |t| [t.key, t] }

        to_generate = []
        outcomes = {}

        items.each do |item|
          tags = (item[:context] || []).map { |k| context_tags_by_key[k] }
          translation = existing[item[:key]]

          if translation && !force && unchanged?(translation, item, tags)
            outcomes[item[:key]] = TranslationOutcome.new(
              status: "completed", translated_text: translation.translated_text,
              detected_language: translation.detected_language, cached: true
            )
          else
            matched_terms = matching_glossary_terms(glossary_terms, item, locale)
            to_generate << item.merge(context_tags: tags, glossary_terms: matched_terms)
          end
        end

        generate_and_persist(project, locale, to_generate, outcomes) unless to_generate.empty?

        outcomes
      end

      def unchanged?(translation, item, tags)
        translation.status == "completed" &&
          translation.source_text == item[:source_text] &&
          translation.context_tags.map(&:key).sort == tags.map(&:key).sort
      end

      def generate_and_persist(project, locale, to_generate, outcomes)
        adapter = Backend::Llm.for_project(project)

        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        begin
          results = adapter.translate(items: to_generate, locale: locale)
        rescue StandardError => e
          duration_ms = elapsed_ms(started_at)
          to_generate.each do |item|
            outcomes[item[:key]] = TranslationOutcome.new(status: "failed", translated_text: nil,
              detected_language: nil, cached: false)
          end
          record_failed_usage(project, locale, adapter, to_generate.size, e.message, duration_ms)
          trace_to_langfuse(project, adapter, to_generate, nil, duration_ms, error_message: e.message)
          warn("LLM translation failed: #{e.message}")
          return
        end
        duration_ms = elapsed_ms(started_at)

        record_usage(project, locale, adapter, results, to_generate.size, duration_ms)
        trace_to_langfuse(project, adapter, to_generate, results, duration_ms, error_message: nil)

        results_by_key = results.to_h { |r| [r.key, r] }

        to_generate.each do |item|
          result = results_by_key[item[:key]]
          unless result
            outcomes[item[:key]] = TranslationOutcome.new(status: "failed", translated_text: nil,
              detected_language: nil, cached: false)
            next
          end

          translation = persist_translation(project, locale, item, result, adapter.model)
          outcomes[item[:key]] = TranslationOutcome.new(
            status: "completed", translated_text: translation.translated_text,
            detected_language: translation.detected_language, cached: false
          )
        end
      end

      def record_usage(project, locale, adapter, results, item_count, duration_ms)
        usage = results.first&.usage
        return unless usage

        Backend::Models::LlmUsageEvent.create(
          project_id: project.id,
          locale_id: locale.id,
          provider: project.llm_config.active_llm_provider_config.provider,
          llm_model: adapter.model,
          input_tokens: usage.input_tokens,
          output_tokens: usage.output_tokens,
          translation_count: item_count,
          success: true,
          duration_ms: duration_ms,
          created_at: Time.now
        )
      end

      # No response was received, so no token counts - only that the call
      # was attempted and failed, which the usage views surface as a
      # success/failure rate alongside the token/cost totals.
      def record_failed_usage(project, locale, adapter, item_count, error_message, duration_ms)
        Backend::Models::LlmUsageEvent.create(
          project_id: project.id,
          locale_id: locale.id,
          provider: project.llm_config.active_llm_provider_config.provider,
          llm_model: adapter.model,
          input_tokens: 0,
          output_tokens: 0,
          translation_count: item_count,
          success: false,
          error_message: error_message&.slice(0, 2000),
          duration_ms: duration_ms,
          created_at: Time.now
        )
      end

      def elapsed_ms(started_at)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      end

      # `ended_at` is captured here (request time), not in the job - the job
      # may run well after this call returns, so it can't stand in for when
      # the LLM call actually happened.
      def trace_to_langfuse(project, adapter, items, results, duration_ms, error_message:)
        config = project.llm_config
        return unless config&.langfuse_configured?

        usage = results&.first&.usage

        Backend::LlmConfigs::Jobs::SendLangfuseTraceJob.perform_async(
          project.id,
          {
            "model" => adapter.model,
            "input" => items.map { |i| { "key" => i[:key], "source_text" => i[:source_text] } },
            "output" => results&.map { |r| { "key" => r.key, "translated_text" => r.translated_text } },
            "input_tokens" => usage&.input_tokens,
            "output_tokens" => usage&.output_tokens,
            "duration_ms" => duration_ms,
            "success" => error_message.nil?,
            "error_message" => error_message,
            "ended_at" => Time.now.utc.iso8601(3)
          }
        )
      end

      def persist_translation(project, locale, item, result, model_used)
        translation = project.translations_dataset.first(locale_id: locale.id, key: item[:key])
        previous_value = translation&.translated_text
        llm_provider = project.llm_config.active_llm_provider_config.provider

        if translation
          translation.update(
            source_text: item[:source_text],
            source_language: item[:source_language],
            detected_language: result.detected_source_language,
            translated_text: result.translated_text,
            status: "completed",
            generated_by: "llm",
            model_used: model_used,
            llm_provider: llm_provider
          )
        else
          translation = Backend::Models::Translation.create(
            project_id: project.id,
            locale_id: locale.id,
            key: item[:key],
            source_text: item[:source_text],
            source_language: item[:source_language],
            detected_language: result.detected_source_language,
            translated_text: result.translated_text,
            status: "completed",
            generated_by: "llm",
            model_used: model_used,
            llm_provider: llm_provider
          )
        end

        # Sequel's many_to_many has no bulk `=` setter (only for
        # many_to_one/one_to_one) - replace membership via add/remove_all.
        translation.remove_all_context_tags
        (item[:context_tags] || []).each { |tag| translation.add_context_tag(tag) }

        translation.record_version!(
          previous_value: previous_value,
          new_value: result.translated_text,
          changed_by_type: "llm"
        )

        translation
      end

      def build_response(items, target_locale_keys, results)
        items.map do |item|
          {
            key: item[:key],
            translations: target_locale_keys.map do |locale_key|
              t = results[locale_key][item[:key]]
              {
                locale: locale_key,
                status: t.status,
                translated_text: t.translated_text,
                detected_language: t.detected_language,
                cached: t.cached
              }
            end
          }
        end
      end
    end
  end
end
