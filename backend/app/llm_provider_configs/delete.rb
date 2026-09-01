# frozen_string_literal: true

module Backend
  module LlmProviderConfigs
    class Delete < Backend::Operation
      def call(config:)
        config.destroy
        config
      end
    end
  end
end
