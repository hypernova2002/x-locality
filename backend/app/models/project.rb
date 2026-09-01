# frozen_string_literal: true

module Backend
  module Models
    class Project < Sequel::Model
      include Concerns::HasPublicId

      public_id_prefix 'proj'

      many_to_one :account
      one_to_one :llm_config
      one_to_many :llm_provider_configs
      one_to_many :api_keys, class: APIKey
      one_to_many :locales
      one_to_many :context_tags
      one_to_many :glossary_terms
      one_to_many :translations
      one_to_many :translation_batches
      one_to_many :project_memberships
      one_to_many :invites
      one_to_many :project_webhooks

      def effective_role_for(user)
        return 'admin' if user.owner? && user.account_id == account_id

        project_memberships_dataset.first(user_id: user.id)&.role
      end
    end
  end
end
