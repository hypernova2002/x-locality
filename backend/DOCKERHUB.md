# XLocality Backend

Hanami 3 (Ruby) API for [XLocality](https://github.com/hypernova2002/x-locality) — a self-hosted translation/localization platform with LLM-backed translation, glossary terms, context tags, bulk translate, usage analytics, and webhooks.

**Source & full docs:** https://github.com/hypernova2002/x-locality
**License:** MIT

## What this image is

This is the `api` service. The exact same image also runs the Sidekiq background worker that processes translation jobs — just override the command.

## Quick start

The fastest way to try both images together, with Postgres and Redis included. Save this as `docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: x_locality
      POSTGRES_USER: x_locality
      POSTGRES_PASSWORD: 35b307542cbebddfa804ecc5260b5d8a
    ports:
      - "5433:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U x_locality"]
      interval: 5s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7
    ports:
      - "6380:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 10

  api:
    image: hypernova2002/x-locality-backend:latest
    environment: &backend-env
      DATABASE_URL: postgres://x_locality:35b307542cbebddfa804ecc5260b5d8a@postgres:5432/x_locality
      SIDEKIQ_REDIS_URL: redis://redis:6379/0
      RACK_ATTACK_REDIS_URL: redis://redis:6379/1
      JWT_SECRET: 7c1c0f4ad5ab55619e56b134e9ff3167535567db20749b2a513ca7b3ee12f5d3
      ENCRYPTION_KEY: ZH/u9FbnmOva+h3ZHzVxTZFm3IaR2HAFLGbYkM+5BdU=
      CORS_ALLOWED_ORIGINS: http://localhost:8080
      FRONTEND_BASE_URL: http://localhost:8080
    ports:
      - "2300:2300"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  worker:
    image: hypernova2002/x-locality-backend:latest
    command: bundle exec sidekiq -r ./config/boot.rb
    environment: *backend-env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  web:
    image: hypernova2002/x-locality-frontend:latest
    environment:
      API_BASE_URL: http://localhost:2300
    ports:
      - "8080:80"
    depends_on:
      - api

volumes:
  postgres_data:
  redis_data:
```

Then:

```bash
docker compose up -d postgres redis
docker compose run --rm api bundle exec rake db:migrate
docker compose up -d
```

Open `http://localhost:8080` and sign up — there's no default account.

**The `JWT_SECRET`/`ENCRYPTION_KEY`/Postgres password above are real, working values, not placeholders** — fine for a quick local evaluation, but generate your own (`openssl rand -hex 32` and `openssl rand -base64 32`) for anything you intend to keep running or expose beyond your own machine.

Testing from a different device than the one running Docker (e.g. a phone on the same network)? Replace every `localhost` above with that machine's LAN IP — a browser elsewhere can't resolve `localhost` to mean this machine.

Currently `linux/amd64` only. On an arm64 machine (Apple Silicon, AWS Graviton, Raspberry Pi, ...), `docker pull` fails with "no matching manifest" unless Docker can emulate amd64 (Docker Desktop does this automatically on Mac; add `platform: linux/amd64` under each image service above if it doesn't happen for you) — it'll work, just slower than a native image.

### Manual `docker run`, without compose

Needs a reachable Postgres database and a Redis instance. Run migrations once before the first boot:

```bash
docker run --rm \
  -e DATABASE_URL=postgres://user:pass@your-postgres:5432/x_locality \
  hypernova2002/x-locality-backend:latest \
  bundle exec rake db:migrate
```

Then run the API:

```bash
docker run -d -p 2300:2300 \
  -e DATABASE_URL=postgres://user:pass@your-postgres:5432/x_locality \
  -e SIDEKIQ_REDIS_URL=redis://your-redis:6379/0 \
  -e RACK_ATTACK_REDIS_URL=redis://your-redis:6379/1 \
  -e JWT_SECRET=$(openssl rand -hex 32) \
  -e ENCRYPTION_KEY=$(openssl rand -base64 32) \
  hypernova2002/x-locality-backend:latest
```

And the background worker (same image, different command):

```bash
docker run -d \
  -e DATABASE_URL=postgres://user:pass@your-postgres:5432/x_locality \
  -e SIDEKIQ_REDIS_URL=redis://your-redis:6379/0 \
  -e RACK_ATTACK_REDIS_URL=redis://your-redis:6379/1 \
  -e JWT_SECRET=... \
  -e ENCRYPTION_KEY=... \
  hypernova2002/x-locality-backend:latest \
  bundle exec sidekiq -r ./config/boot.rb
```

## Environment variables

### Required

| Variable | Description |
|---|---|
| `DATABASE_URL` | Postgres connection string, e.g. `postgres://user:pass@host:5432/db_name` |
| `SIDEKIQ_REDIS_URL` | Redis URL for the background job queue, e.g. `redis://host:6379/0` |
| `RACK_ATTACK_REDIS_URL` | Redis URL for rate limiting, e.g. `redis://host:6379/1` (can be the same Redis instance, a different db number) |
| `JWT_SECRET` | Random secret used to sign admin session JWTs. Generate with `openssl rand -hex 32`. |
| `ENCRYPTION_KEY` | Base64-encoded 32-byte key used to encrypt each project's LLM provider API keys at rest. Generate with `openssl rand -base64 32`. **Back this up** — losing it makes every stored LLM API key permanently unrecoverable. |

### Optional

| Variable | Default | Description |
|---|---|---|
| `HANAMI_PORT` | `2300` | Port the API listens on |
| `HANAMI_MAX_THREADS` / `HANAMI_MIN_THREADS` | `5` | Puma thread pool size per process |
| `HANAMI_WEB_CONCURRENCY` | `0` (single process) | Number of Puma worker processes; a value >1 enables cluster mode |
| `CORS_ALLOWED_ORIGINS` | *(empty)* | Comma-separated list of origins allowed to call the API from a browser — set this to your frontend's URL |
| `JWT_ACCESS_TOKEN_TTL` | `86400` (24h) | Admin access token lifetime, in seconds |
| `JWT_REFRESH_TOKEN_TTL` | `2592000` (30d) | Admin refresh token lifetime, in seconds |
| `SYNC_TRANSLATION_UNIT_LIMIT` | `50` | Max items × locales per synchronous translation request (the external, API-key-authenticated endpoint) |
| `BATCH_TRANSLATION_UNIT_LIMIT` | `1000` | Max items × locales per bulk-translate request from the admin UI |
| `SMTP_HOST` / `SMTP_PORT` | *(none)* | SMTP server for budget-alert and invite emails |
| `MAIL_FROM` | *(none)* | From address for outgoing emails |
| `FRONTEND_BASE_URL` | `http://localhost:5173` | Used to build invite-accept links in invite emails — set to your actual frontend URL |
| `LANGFUSE_BASE_URL` | *(empty)* | Self-hosted Langfuse instance URL for optional per-project LLM call tracing. Leave unset to disable. |

LLM provider credentials (Anthropic, OpenAI, Gemini, Amazon Bedrock, Amazon Translate) are configured per-project through the admin UI once it's running, not as environment variables.

## Health check

`GET /health` returns `200 OK` once the app is up — use it as your container/orchestrator health check.

## API reference

The external, API-key-authenticated translation API has an interactive OpenAPI reference built in, served at `/api-docs` by this same image.

## Links

- Source & README: https://github.com/hypernova2002/x-locality
- Frontend image: https://hub.docker.com/r/hypernova2002/x-locality-frontend
- User guide: https://hypernova2002.github.io/x-locality/
- Issues: https://github.com/hypernova2002/x-locality/issues

Everything past "the app boots and serves traffic" — TLS termination, real production infrastructure, backups, error tracking, a full deployment pipeline — is left to whoever runs this; it's out of scope for the image itself. See the main repo README for the full setup guide.
