# frozen_string_literal: true

require 'mail'

module Backend
  module LlmConfigs
    class BudgetAlertMailer
      def self.deliver(project:, config:, tokens_used:, cost_used:)
        settings = Hanami.app['settings']
        account = project.account
        layout = Backend::Emails::BrandedLayout

        title = "#{project.name} has crossed #{config.alert_threshold_percent}% of its LLM budget"
        token_line = if config.monthly_token_limit
                       "Monthly token limit: #{config.monthly_token_limit} (#{tokens_used} used this month)"
                     else
                       'Monthly token limit: not set'
                     end
        cost_line = if config.monthly_cost_limit_usd
                      "Monthly cost limit: $#{config.monthly_cost_limit_usd} ($#{format('%.2f',
                                                                                        cost_used)} used this month)"
                    else
                      'Monthly cost limit: not set'
                    end
        explainer = 'Once either limit is fully reached, new translation requests for this project will be ' \
                    'blocked until the limit is raised or the month rolls over. Review usage and adjust limits from ' \
                    "the project's Settings page."

        body_text = [token_line, cost_line, '', explainer].join("\n")
        body_html = "<p>#{layout.escape(token_line)}<br>#{layout.escape(cost_line)}</p><p>#{layout.escape(explainer)}</p>"

        Mail.deliver do
          delivery_method :smtp, address: settings.smtp_host, port: settings.smtp_port

          from layout.from_header(account)
          to config.alert_email
          subject "XLocality: #{title}"

          text_part { body layout.text(account: account, title: title, body_text: body_text) }
          html_part do
            content_type 'text/html; charset=UTF-8'
            body layout.html(account: account, title: title, body_html: body_html)
          end
        end
      end

      def self.deliver_test(project:, config:)
        settings = Hanami.app['settings']
        account = project.account
        layout = Backend::Emails::BrandedLayout

        title = "Test alert for #{project.name}"
        threshold = config.alert_threshold_percent ? "#{config.alert_threshold_percent}%" : 'the configured threshold'
        message = "If you're seeing this, the alert address is configured correctly - when usage crosses " \
                  "#{threshold} of either monthly limit, a similar email will be sent here automatically. No action needed."

        Mail.deliver do
          delivery_method :smtp, address: settings.smtp_host, port: settings.smtp_port

          from layout.from_header(account)
          to config.alert_email
          subject "XLocality: #{title}"

          text_part { body layout.text(account: account, title: title, body_text: message) }
          html_part do
            content_type 'text/html; charset=UTF-8'
            body layout.html(account: account, title: title, body_html: "<p>#{layout.escape(message)}</p>")
          end
        end
      end
    end
  end
end
