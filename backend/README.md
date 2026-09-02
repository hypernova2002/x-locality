# Backend

Hanami 3 API — Ruby, Sequel for persistence (no hanami-db/ROM), Postgres, Redis/Sidekiq for background jobs. See the [root README](../README.md) for setup, running the full stack, and common tasks — everything here runs via `docker compose`, not host Ruby/Bundler, so `bin/setup`/`bin/dev` aren't used.

## Structure

```
backend/
  app/
    actions/api/v1/          # HTTP layer - params contracts, auth, calls one operation, serializes the result
      admin/                   # JWT-authenticated - everything the Vue admin UI calls
    <domain>/                 # Operations (Backend::Operation, a thin dry-operation wrapper) - one file per
                                # use case (create.rb, update.rb, ...), namespaced by domain (translations/,
                                # projects/, glossary_terms/, project_webhooks/, ...)
    models/                   # Sequel::Model classes
    serializers/               # Alba serializers, one per resource
  config/
    app.rb                    # Middleware stack
    routes.rb                 # api/v1 (API-key auth) and admin/v1 (JWT auth) scopes
    settings.rb                # All config sourced from environment variables (docker-compose.yml), no .env files
    openapi_ruby.rb             # OpenAPI spec/validation config - see "API documentation" below
    api_components/             # OpenAPI schema components (Ruby classes)
    providers/                   # db, sidekiq, rack_attack setup
  db/migrate/                 # Sequel migrations
  lib/backend/                # Framework-agnostic code with no app dependency (crypto, JWT, LLM adapters, ...)
  spec/                       # RSpec - mostly operation-level specs; spec/requests/ is HTTP-level (see below)
```

## Operations vs. actions

Business logic lives in **operations** (`app/<domain>/*.rb`), plain `Backend::Operation` (dry-operation) classes called directly from specs and from **actions**. Actions (`app/actions/api/v1/**`) are the thin HTTP layer: parse/validate params, call one operation, map the `Success`/`Failure` result to a response. This split is why most specs instantiate an operation directly rather than making an HTTP request.

## API documentation

The external, API-key-authenticated surface (`/api/v1/translations`) has an OpenAPI 3.1 reference generated with [openapi-ruby](https://github.com/openapi-ruby/openapi-ruby) and served live at `/api-docs` (Swagger UI) by this app. It's generated from `spec/requests/**/*_spec.rb`, not hand-written, and runtime request/response validation is enabled for that path — a mismatch between the spec and actual behavior fails loudly rather than drifting silently. It does not cover `/api/v1/admin/*`, which is internal to the Vue admin UI.

After changing a documented endpoint or its `spec/requests/**/*_spec.rb`, regenerate and commit the spec:

```bash
docker compose run --rm api bundle exec rake openapi_ruby:generate
```

## Linting

`bundle exec rubocop` runs automatically on staged files via the repo's Lefthook pre-commit hook (see root README). Pre-existing offenses are grandfathered into `.rubocop_todo.yml`; new code should pass cleanly.
