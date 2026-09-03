# XLocality Frontend

Vue 3 admin UI for [XLocality](https://github.com/hypernova2002/x-locality) — a self-hosted translation/localization platform. This image serves the built app via nginx.

**Source & full docs:** https://github.com/hypernova2002/x-locality
**License:** MIT
**Backend image:** https://hub.docker.com/r/hypernova2002/x-locality-backend

## Quick start

The fastest way to try this together with the [backend API image](https://hub.docker.com/r/hypernova2002/x-locality-backend), Postgres, and Redis. Save this as `docker-compose.yml`:

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

Testing from a different device than the one running Docker (e.g. a phone on the same network)? Replace every `localhost` above with that machine's LAN IP - a browser elsewhere can't resolve `localhost` to mean this machine.

Currently `linux/amd64` only. On an arm64 machine (Apple Silicon, AWS Graviton, Raspberry Pi, ...), `docker pull` fails with "no matching manifest" unless Docker can emulate amd64 (Docker Desktop does this automatically on Mac; add `platform: linux/amd64` under each image service above if it doesn't happen for you) - it'll work, just slower than a native image.

### Manual `docker run`, without compose

Needs the backend API image (or a compatible deployment of it) already running somewhere reachable:

```bash
docker run -d -p 80:80 \
  -e API_BASE_URL=https://api.your-domain.com \
  hypernova2002/x-locality-frontend:latest
```

Open the container's port in a browser and sign up for an account.

## How the API URL is configured

Unlike a typical Vite build, the API URL is **not** baked into the image at build time — Vite env vars only exist at build time, which would otherwise pin every published image to whatever URL happened to be set when *this specific image* was built, making it useless for anyone else. Instead, `API_BASE_URL` is read at container *start* and written into a small `config.js` file the app loads before it boots, so the same published image works against any backend you point it at.

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `API_BASE_URL` | Yes | Full URL, including scheme, of the XLocality backend API this UI should call, e.g. `https://api.your-domain.com`. Must be reachable from the *browser*, not just from this container. |

## Routing

This is a single-page app using client-side (history-mode) routing — the bundled nginx config already handles the fallback to `index.html` for you. If you put this behind your own reverse proxy, forward everything to this container as-is; no special routing rules needed on your end.

## Links

- Source & README: https://github.com/hypernova2002/x-locality
- Backend image: https://hub.docker.com/r/hypernova2002/x-locality-backend
- User guide: https://hypernova2002.github.io/x-locality/
- Issues: https://github.com/hypernova2002/x-locality/issues

Everything past "the app boots and serves traffic" — TLS termination, a CDN, a full deployment pipeline — is left to whoever runs this; it's out of scope for the image itself. See the main repo README for the full setup guide.
