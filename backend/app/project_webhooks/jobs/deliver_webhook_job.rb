# frozen_string_literal: true

require 'sidekiq'
require 'net/http'
require 'openssl'
require 'json'

module Backend
  module ProjectWebhooks
    module Jobs
      class DeliverWebhookJob
        include Sidekiq::Job

        def perform(project_webhook_id, event_type, payload)
          webhook = Backend::Models::ProjectWebhook[project_webhook_id]
          return unless webhook&.enabled

          body = { event: event_type, data: payload, timestamp: Time.now.utc.iso8601 }.to_json
          signature = OpenSSL::HMAC.hexdigest('SHA256', webhook.secret, body)

          response_status = nil
          error_message = nil
          success = false

          begin
            uri = URI.parse(webhook.url)
            request = Net::HTTP::Post.new(uri)
            request['Content-Type'] = 'application/json'
            request['X-Webhook-Event'] = event_type
            request['X-Webhook-Signature'] = "sha256=#{signature}"
            request.body = body

            response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                           open_timeout: 5, read_timeout: 10) { |http| http.request(request) }

            response_status = response.code.to_i
            success = response.is_a?(Net::HTTPSuccess)
            error_message = "HTTP #{response.code}" unless success
          rescue StandardError => e
            error_message = e.message.to_s.slice(0, 2000)
          end

          Backend::Models::WebhookDelivery.create(
            project_webhook_id: webhook.id, event_type: event_type, payload: body,
            response_status: response_status, success: success, error_message: error_message
          )

          raise "Webhook delivery failed: #{error_message}" unless success
        end
      end
    end
  end
end
