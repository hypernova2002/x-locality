# frozen_string_literal: true

module Backend
  module LlmProviderConfigs
    # Stateless: lists models for whatever provider/key the caller passes in
    # (typically not-yet-saved values from the create/edit form), so a model
    # can be picked before the config is saved.
    class ListModels < Backend::Operation
      def call(provider:, api_key:)
        step check_present(provider, api_key)

        step fetch_models(provider, api_key)
      end

      private

      def check_present(provider, api_key)
        if provider.nil? || provider.empty? || api_key.nil? || api_key.empty?
          return Failure([:unconfigured, "Provider and API key are required to list models"])
        end

        Success(true)
      end

      def fetch_models(provider, api_key)
        Success(Backend::Llm.list_models(provider: provider, api_key: api_key))
      rescue StandardError => e
        Failure([:unconfigured, "Could not list models: #{e.message}"])
      end
    end
  end
end
