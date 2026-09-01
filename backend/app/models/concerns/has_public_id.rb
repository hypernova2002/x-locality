# frozen_string_literal: true

module Backend
  module Models
    module Concerns
      module HasPublicId
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def public_id_prefix(prefix)
            const_set(:PUBLIC_ID_PREFIX, prefix)
          end
        end

        def before_create
          self.public_id ||= Backend::PublicId.generate(self.class::PUBLIC_ID_PREFIX)
          super
        end
      end
    end
  end
end
