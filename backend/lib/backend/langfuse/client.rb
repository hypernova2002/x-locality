# frozen_string_literal: true

require 'net/http'
require 'json'
require 'securerandom'
require 'base64'

module Backend
  module Langfuse
    # Sends one OTLP-over-HTTP trace (one "generation" span) per LLM call to
    # a self-hosted Langfuse instance - see
    # https://langfuse.com/integrations/native/opentelemetry for the
    # langfuse.observation.* attribute set. Hand-rolled rather than pulling
    # in the full opentelemetry-ruby SDK: Langfuse's own attributes are
    # plain JSON-string-valued OTLP span attributes, and we only ever emit
    # a single span per call, so the SDK's context propagation/batching
    # machinery buys nothing here.
    class Client
      class DeliveryError < StandardError; end

      def initialize(base_url:, public_key:, secret_key:)
        @base_url = base_url
        @public_key = public_key
        @secret_key = secret_key
      end

      def send_generation(trace)
        uri = URI.join(@base_url, '/api/public/otel/v1/traces')
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request['Authorization'] = "Basic #{Base64.strict_encode64("#{@public_key}:#{@secret_key}")}"
        request['x-langfuse-ingestion-version'] = '4'
        request.body = build_payload(trace).to_json

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        return if response.is_a?(Net::HTTPSuccess)

        raise DeliveryError, "Langfuse ingestion failed: #{response.code} #{response.body}"
      end

      private

      def build_payload(trace)
        ended_at = Time.iso8601(trace.fetch('ended_at'))
        started_at = ended_at - (trace.fetch('duration_ms') / 1000.0)
        success = trace.fetch('success')

        {
          resourceSpans: [
            {
              resource: { attributes: [string_attr('service.name', 'x-locality')] },
              scopeSpans: [
                {
                  scope: { name: 'x-locality' },
                  spans: [
                    {
                      traceId: SecureRandom.hex(16),
                      spanId: SecureRandom.hex(8),
                      name: 'translate',
                      kind: 1,
                      startTimeUnixNano: unix_nano(started_at),
                      endTimeUnixNano: unix_nano(ended_at),
                      attributes: span_attributes(trace, success),
                      status: { code: success ? 1 : 2 }
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      def span_attributes(trace, success)
        attributes = [
          string_attr('langfuse.trace.name', 'translate'),
          string_attr('langfuse.observation.type', 'generation'),
          string_attr('langfuse.observation.level', success ? 'DEFAULT' : 'ERROR'),
          string_attr('langfuse.observation.model.name', trace['model']),
          string_attr('langfuse.observation.input', trace['input'].to_json)
        ]
        attributes << string_attr('langfuse.observation.output', trace['output'].to_json) if trace['output']
        if trace['error_message']
          attributes << string_attr('langfuse.observation.status_message', trace['error_message'])
        end

        if trace['input_tokens'] || trace['output_tokens']
          input_tokens = trace['input_tokens'].to_i
          output_tokens = trace['output_tokens'].to_i
          usage = { input: input_tokens, output: output_tokens, total: input_tokens + output_tokens }
          attributes << string_attr('langfuse.observation.usage_details', usage.to_json)
        end

        attributes
      end

      def unix_nano(time)
        (time.to_r * 1_000_000_000).to_i.to_s
      end

      def string_attr(key, value)
        { key: key, value: { stringValue: value.to_s } }
      end
    end
  end
end
