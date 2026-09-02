# frozen_string_literal: true

module Backend
  module LlmProviderConfigs
    # Stateless: lists models for whatever provider/key the caller passes in
    # (typically not-yet-saved values from the create/edit form), so a model
    # can be picked before the config is saved.
    class ListModels < Backend::Operation
      AWS_PROVIDERS = %w[bedrock aws_translate].freeze

      def call(provider:, api_key:, api_secret: nil, region: nil)
        step check_present(provider, api_key, api_secret, region)

        step fetch_models(provider, api_key, api_secret, region)
      end

      private

      def check_present(provider, api_key, api_secret, region)
        if provider.nil? || provider.empty? || api_key.nil? || api_key.empty?
          return Failure([:unconfigured, 'Provider and API key are required to list models'])
        end

        if AWS_PROVIDERS.include?(provider) && (api_secret.nil? || api_secret.empty? || region.nil? || region.empty?)
          return Failure([:unconfigured, 'AWS secret key and region are required to list models for this provider'])
        end

        Success(true)
      end

      def fetch_models(provider, api_key, api_secret, region)
        Success(Backend::Llm.list_models(provider: provider, api_key: api_key, api_secret: api_secret,
                                         region: region))
      rescue StandardError => e
        Failure([:unconfigured, "Could not list models: #{e.message}"])
      end
    end
  end
end
