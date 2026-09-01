# XLocality

Translation/localisation API. Ruby/Hanami backend using Sequel for persistence, with a Vue UI to follow. Everything runs in Docker — no Ruby, Postgres, or Redis needs to be installed on your machine.

## Prerequisites

- Docker and Docker Compose (`docker compose version` to check)

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
- `api` — the Hanami app at [http://localhost:2300](http://localhost:2300), with live reload (Guard watches `app/`, `config/`, `lib/` and restarts on change — no rebuild needed for code changes)
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
```

Rebuild images after changing the `Gemfile` or `Dockerfile`:

```bash
docker compose build
```

## Project structure

```
x-locality/
  docker-compose.example.yml   # tracked template — copy to docker-compose.yml
  docker-compose.yml           # your local copy with real secrets (gitignored)
  backend/                     # Hanami API (Ruby 4.0, Sequel, Postgres)
    config/
      app.rb                   # middleware (Rack::Attack)
      routes.rb                # api/v1 (API-key auth) and admin/v1 (JWT auth) scopes
      settings.rb               # all config sourced from environment variables
      providers/                 # db, sidekiq, rack_attack setup
    db/migrate/                  # Sequel migrations
  frontend/                    # Vue UI (Vite, TypeScript, openvue components)
  docs/                        # User guide (VitePress) - see docs/README.md
```

## Documentation

The user guide lives in `docs/` (VitePress) and is deployed to GitHub Pages on every push to `main` that touches it (see `.github/workflows/deploy-docs.yml`). See [`docs/README.md`](docs/README.md) for how to write pages and add screenshots.
