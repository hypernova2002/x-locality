# frozen_string_literal: true

module Backend
  class Routes < Hanami::Routes
    get '/health', to: ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }

    mount OpenapiRuby::RackApp, at: '/api-docs'

    scope 'api/v1' do
      # Translation API (API-key auth) - server-to-server, no CORS.
      post '/translations', to: 'api.v1.translations.create'
      get '/translations', to: 'api.v1.translations.index'
      get '/translations/:key', to: 'api.v1.translations.show'

      # Admin section of the API (JWT auth) - called from the Vue SPA,
      # CORS scoped here only.
      scope 'admin' do
        use Rack::Cors do |cors|
          cors.allow do |allow|
            allow.origins(*Hanami.app['settings'].cors_allowed_origins)
            allow.resource '*', headers: :any, methods: %i[get post patch delete], credentials: false,
                                expose: %w[X-Total-Count]
          end
        end

        post '/auth/signup', to: 'api.v1.admin.auth.signup'
        post '/auth/login', to: 'api.v1.admin.auth.login'

        # Public - the invited person has no account/JWT yet.
        get '/invites/:token', to: 'api.v1.admin.invites.show'
        post '/invites/:token/accept', to: 'api.v1.admin.invites.accept'

        get '/usage/requests', to: 'api.v1.admin.usage.requests'
        get '/usage/llm', to: 'api.v1.admin.usage.llm'

        get '/account', to: 'api.v1.admin.account.show'
        patch '/account', to: 'api.v1.admin.account.update'
        delete '/account', to: 'api.v1.admin.account.delete'
        post '/account/transfer_ownership', to: 'api.v1.admin.account.transfer_ownership'
        get '/account/users', to: 'api.v1.admin.account.users.index'
        delete '/account/users/:id', to: 'api.v1.admin.account.users.delete'

        get '/projects', to: 'api.v1.admin.projects.index'
        post '/projects', to: 'api.v1.admin.projects.create'
        get '/projects/:project_id', to: 'api.v1.admin.projects.show'
        patch '/projects/:project_id', to: 'api.v1.admin.projects.update'
        delete '/projects/:project_id', to: 'api.v1.admin.projects.delete'

        get '/projects/:project_id/usage/requests', to: 'api.v1.admin.projects.usage.requests'
        get '/projects/:project_id/usage/llm', to: 'api.v1.admin.projects.usage.llm'
        get '/projects/:project_id/usage/translations', to: 'api.v1.admin.projects.usage.translations'

        get '/projects/:project_id/llm_config', to: 'api.v1.admin.projects.llm_config.show'
        patch '/projects/:project_id/llm_config', to: 'api.v1.admin.projects.llm_config.update'
        post '/projects/:project_id/llm_config/test_alert', to: 'api.v1.admin.projects.llm_config.test_alert'

        get '/projects/:project_id/llm_provider_configs', to: 'api.v1.admin.projects.llm_provider_configs.index'
        post '/projects/:project_id/llm_provider_configs', to: 'api.v1.admin.projects.llm_provider_configs.create'
        patch '/projects/:project_id/llm_provider_configs/:id', to: 'api.v1.admin.projects.llm_provider_configs.update'
        delete '/projects/:project_id/llm_provider_configs/:id', to: 'api.v1.admin.projects.llm_provider_configs.delete'
        post '/projects/:project_id/llm_provider_configs/models',
             to: 'api.v1.admin.projects.llm_provider_configs.models'

        get '/projects/:project_id/members', to: 'api.v1.admin.projects.members.index'
        post '/projects/:project_id/members', to: 'api.v1.admin.projects.members.create'
        patch '/projects/:project_id/members/:user_id', to: 'api.v1.admin.projects.members.update'
        delete '/projects/:project_id/members/:user_id', to: 'api.v1.admin.projects.members.delete'

        get '/projects/:project_id/invites', to: 'api.v1.admin.projects.invites.index'
        post '/projects/:project_id/invites', to: 'api.v1.admin.projects.invites.create'
        delete '/projects/:project_id/invites/:id', to: 'api.v1.admin.projects.invites.delete'

        get '/projects/:project_id/api_keys', to: 'api.v1.admin.projects.api_keys.index'
        post '/projects/:project_id/api_keys', to: 'api.v1.admin.projects.api_keys.create'
        post '/projects/:project_id/api_keys/:id/revoke', to: 'api.v1.admin.projects.api_keys.revoke'
        delete '/projects/:project_id/api_keys/:id', to: 'api.v1.admin.projects.api_keys.delete'

        get '/projects/:project_id/locales', to: 'api.v1.admin.projects.locales.index'
        post '/projects/:project_id/locales', to: 'api.v1.admin.projects.locales.create'
        get '/projects/:project_id/locales/export', to: 'api.v1.admin.projects.locales.export'
        post '/projects/:project_id/locales/import', to: 'api.v1.admin.projects.locales.import'
        patch '/projects/:project_id/locales/:id', to: 'api.v1.admin.projects.locales.update'
        delete '/projects/:project_id/locales/:id', to: 'api.v1.admin.projects.locales.delete'
        get '/projects/:project_id/locales/:id/bulk_translate_candidates',
            to: 'api.v1.admin.projects.locales.bulk_translate_candidates'
        post '/projects/:project_id/locales/:id/bulk_translate', to: 'api.v1.admin.projects.locales.bulk_translate'

        get '/projects/:project_id/context_tags', to: 'api.v1.admin.projects.context_tags.index'
        post '/projects/:project_id/context_tags', to: 'api.v1.admin.projects.context_tags.create'
        get '/projects/:project_id/context_tags/export', to: 'api.v1.admin.projects.context_tags.export'
        post '/projects/:project_id/context_tags/import', to: 'api.v1.admin.projects.context_tags.import'
        patch '/projects/:project_id/context_tags/:id', to: 'api.v1.admin.projects.context_tags.update'
        delete '/projects/:project_id/context_tags/:id', to: 'api.v1.admin.projects.context_tags.delete'

        get '/projects/:project_id/glossary_terms', to: 'api.v1.admin.projects.glossary_terms.index'
        post '/projects/:project_id/glossary_terms', to: 'api.v1.admin.projects.glossary_terms.create'
        get '/projects/:project_id/glossary_terms/export', to: 'api.v1.admin.projects.glossary_terms.export'
        post '/projects/:project_id/glossary_terms/import', to: 'api.v1.admin.projects.glossary_terms.import'
        patch '/projects/:project_id/glossary_terms/:id', to: 'api.v1.admin.projects.glossary_terms.update'
        delete '/projects/:project_id/glossary_terms/:id', to: 'api.v1.admin.projects.glossary_terms.delete'

        get '/projects/:project_id/webhooks', to: 'api.v1.admin.projects.webhooks.index'
        post '/projects/:project_id/webhooks', to: 'api.v1.admin.projects.webhooks.create'
        patch '/projects/:project_id/webhooks/:id', to: 'api.v1.admin.projects.webhooks.update'
        delete '/projects/:project_id/webhooks/:id', to: 'api.v1.admin.projects.webhooks.delete'
        get '/projects/:project_id/webhooks/:id/deliveries', to: 'api.v1.admin.projects.webhooks.deliveries'
        post '/projects/:project_id/webhooks/:id/test', to: 'api.v1.admin.projects.webhooks.test'

        get '/projects/:project_id/translations', to: 'api.v1.admin.projects.translations.index'
        post '/projects/:project_id/translations/bulk_delete', to: 'api.v1.admin.projects.translations.bulk_delete'
        post '/projects/:project_id/translations/bulk_regenerate',
             to: 'api.v1.admin.projects.translations.bulk_regenerate'
        get '/projects/:project_id/translations/export', to: 'api.v1.admin.projects.translations.export'
        post '/projects/:project_id/translations/import', to: 'api.v1.admin.projects.translations.import'
        get '/projects/:project_id/translations/by_key/:key', to: 'api.v1.admin.projects.translations.show_by_key'
        post '/projects/:project_id/translations/by_key/:key/lock', to: 'api.v1.admin.projects.translations.lock'
        post '/projects/:project_id/translations/by_key/:key/unlock', to: 'api.v1.admin.projects.translations.unlock'
        post '/projects/:project_id/translations/by_key/:key/locales',
             to: 'api.v1.admin.projects.translations.add_locale'
        get '/projects/:project_id/translations/:id', to: 'api.v1.admin.projects.translations.show'
        patch '/projects/:project_id/translations/:id', to: 'api.v1.admin.projects.translations.update'
        post '/projects/:project_id/translations/:id/regenerate', to: 'api.v1.admin.projects.translations.regenerate'
        get '/projects/:project_id/translations/:id/versions', to: 'api.v1.admin.projects.translations.versions'
      end
    end
  end
end
