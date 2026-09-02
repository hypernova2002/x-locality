# XLocality

Translation/localisation platform: a Hanami 3 (Ruby) API using Sequel for persistence, with a Vue 3 admin UI. Everything runs in Docker — no Ruby, Node, Postgres, or Redis needs to be installed on your machine.

## Prerequisites

- Docker and Docker Compose (`docker compose version` to check)
- [Lefthook](https://github.com/evilmartians/lefthook) for the pre-commit lint hook — `brew install lefthook`, then `lefthook install` once after cloning. The hook commands themselves (`rubocop`, `eslint`/`oxlint`) run inside Docker, same as everything else.

## Setup

1. Copy the example compose file — `docker-compose.yml` is gitignored since it holds your local secrets:

   ```bash
   cp docker-compose.example.yml docker-compose.yml
   ```

2. Edit `docker-compose.yml` and set a real `ENCRYPTION_KEY` under the `api` and `worker` services — a base64-encoded 32-byte value, e.g. `openssl rand -base64 32`. This encrypts project-level LLM API keys at rest (LLM provider/API key are configured per-project via the admin API, not as global env vars — see below). Everything else has a working development default and can be left as-is.

3. Build the images and run the initial database migration:

   ```bash
   docker compose build
   docker compose run --rm api bundle exec rake db:migrate
   ```

## Running the app

```bash
docker compose up
```

This starts:

- `postgres` — Postgres 16, exposed on host port `5433`
- `redis` — Redis 7, exposed on host port `6380` (Sidekiq uses db 0, rack-attack uses db 1)
- `api` — the Hanami app at [http://localhost:2300](http://localhost:2300), with live reload (Guard watches `app/`, `config/`, `lib/` and restarts on change — no rebuild needed for code changes). Interactive API reference (Swagger UI) at [http://localhost:2300/api-docs](http://localhost:2300/api-docs).
- `worker` — Sidekiq, processing background translation jobs
- `web` — the Vue admin UI at [http://localhost:5173](http://localhost:5173)
- `docs` — the user guide (VitePress) at [http://localhost:5174](http://localhost:5174), live-reloading as you edit files under `docs/`

Check it's up:

```bash
curl http://localhost:2300/health
```

Stop everything with `docker compose down` (add `-v` to also wipe the Postgres/Redis volumes).

## Common tasks

Run these with the stack up (`docker compose up -d`) or standalone via `docker compose run --rm api <command>`:

```bash
# Run migrations
docker compose run --rm api bundle exec rake db:migrate

# Roll back the last migration
docker compose run --rm api bundle exec rake db:rollback

# Rails/Hanami console
docker compose run --rm api bundle exec hanami console

# Run the test suite
docker compose run --rm api bundle exec rspec

# Add a gem: edit backend/Gemfile, then
docker compose run --rm api bundle install
docker compose build api worker   # picks up the new Gemfile.lock in the image

# Regenerate the OpenAPI spec (backend/openapi/public_api.yaml) after editing
# a spec/requests/**/*_spec.rb file - it's committed, not built on deploy, so
# this has to be run and the result committed whenever a documented endpoint
# changes.
docker compose run --rm api bundle exec rake openapi_ruby:generate
```

Rebuild images after changing the `Gemfile` or `Dockerfile`:

```bash
docker compose build
```

## Production images

Pushing a semver-formatted git tag (e.g. `v1.2.3`) builds `backend/Dockerfile.production` and `frontend/Dockerfile.production` and publishes both to GHCR and Docker Hub (see `.github/workflows/release.yml`):

- `ghcr.io/<owner>/x-locality-backend:1.2.3` / `docker.io/<dockerhub-username>/x-locality-backend:1.2.3` (both also tagged `latest`) — serves as the `api`; override the command (`bundle exec sidekiq -r ./config/boot.rb`) to run the same image as the `worker` instead. Needs the same required env vars as local dev (`DATABASE_URL`, `SIDEKIQ_REDIS_URL`, `RACK_ATTACK_REDIS_URL`, `JWT_SECRET`, `ENCRYPTION_KEY` — see `docker-compose.example.yml`), pointed at real infrastructure instead of the dev containers.
- `ghcr.io/<owner>/x-locality-frontend:1.2.3` / `docker.io/<dockerhub-username>/x-locality-frontend:1.2.3` — nginx serving the built static app. The API URL is read at container *start*, not baked into the build, so the same image works against any backend:

  ```bash
  docker run -p 80:80 -e API_BASE_URL=https://api.your-domain.com ghcr.io/<owner>/x-locality-frontend:1.2.3
  ```

GHCR needs no setup (uses the workflow's own `GITHUB_TOKEN`). Docker Hub publishing needs two repo secrets first — **Settings → Secrets and variables → Actions**: `DOCKERHUB_USERNAME` (your Docker Hub username) and `DOCKERHUB_TOKEN` (an access token from Docker Hub's **Account Settings → Security**, not your account password). Without these two secrets set, the release workflow fails at the Docker Hub login step.

These two `Dockerfile.production` files are separate from `backend/Dockerfile`/`frontend/Dockerfile`, which `docker compose` uses for local dev (live reload, dev/test gem groups included on the backend, Vite's dev server on the frontend rather than a `vite build` served by nginx) — don't edit one expecting it to affect the other.

Everything past "the app boots and serves traffic" — secrets management, TLS termination, an actual Postgres/Redis you administer, error tracking, a deploy pipeline beyond publishing the image — is left to whoever is running this in production; it's out of scope for the repo itself.

## Project structure

```
x-locality/
  docker-compose.example.yml   # tracked template — copy to docker-compose.yml
  docker-compose.yml           # your local copy with real secrets (gitignored)
  backend/                     # Hanami API (Ruby 4.0, Sequel, Postgres)
    Dockerfile                  # Local dev image (docker compose)
    Dockerfile.production        # Published release image - see "Production images" below
    config/
      app.rb                   # middleware (Rack::Attack, openapi-ruby validation)
      routes.rb                # api/v1 (API-key auth) and admin/v1 (JWT auth) scopes
      settings.rb               # all config sourced from environment variables
      providers/                 # db, sidekiq, rack_attack setup
      openapi_ruby.rb            # OpenAPI schema/validation config - see Documentation below
      api_components/            # OpenAPI schema components (Ruby classes)
    db/migrate/                  # Sequel migrations
    spec/requests/                # HTTP-level specs that generate the OpenAPI spec (bundle exec rake openapi_ruby:generate)
    openapi/                     # Generated OpenAPI spec (committed - served live at /api-docs)
  frontend/                    # Vue UI (Vite, TypeScript, openvue components)
    Dockerfile                  # Local dev image (docker compose) - Vite dev server
    Dockerfile.production        # Published release image - vite build, served by nginx
    docker/                       # nginx config + runtime API-URL injection for the above
  docs/                        # User guide (VitePress) - see docs/README.md
```

## Documentation

The user guide lives in `docs/` (VitePress) and is deployed to GitHub Pages on every push to `main` that touches it (see `.github/workflows/deploy-docs.yml`). See [`docs/README.md`](docs/README.md) for how to write pages and add screenshots.

The external, API-key-authenticated surface (`/api/v1/translations`) has an OpenAPI 3.1 reference, generated with [openapi-ruby](https://github.com/openapi-ruby/openapi-ruby) from `backend/spec/requests/**/*_spec.rb` and served live at `/api-docs` (Swagger UI) by the `api` service itself. Runtime request/response validation is also enabled for that same path prefix, so a mismatch between the spec and the actual behavior fails loudly (400/500) rather than drifting silently. It does not cover `/api/v1/admin/*`, which is internal to the Vue admin UI.
