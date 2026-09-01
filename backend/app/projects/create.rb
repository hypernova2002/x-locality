# frozen_string_literal: true

module Backend
  module Projects
    class Create < Backend::Operation
      def call(account:, name:, created_by_user:)
        slug = Backend::Slug.generate(name)
        step check_slug_available(account, slug)

        project = nil
        Backend::Models::Project.db.transaction do
          project = Backend::Models::Project.create(
            account_id: account.id,
            name: name,
            slug: slug
          )

          # The owner already has implicit admin access everywhere - an
          # explicit membership row would be redundant and would need
          # upkeep if ownership is ever transferred later.
          unless created_by_user.owner?
            Backend::Models::ProjectMembership.create(project_id: project.id, user_id: created_by_user.id,
                                                      role: 'admin')
          end

          Backend::Models::LlmConfig.create(project_id: project.id)

          Backend::SystemLocales.each do |code, language|
            Backend::Models::Locale.create(
              project_id: project.id,
              key: code,
              target_language: code,
              general_description: "#{language} - standard #{code} localisation",
              system: true
            )
          end
        end

        project
      end

      private

      def check_slug_available(account, slug)
        if Backend::Models::Project.first(account_id: account.id, slug: slug)
          return Failure([:conflict, 'A project with this name already exists'])
        end

        Success(true)
      end
    end
  end
end
