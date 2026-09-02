# XLocality Frontend

Vue 3 admin UI for [XLocality](https://github.com/hypernova2002/x-locality) — a self-hosted translation/localization platform. This image serves the built app via nginx.

**Source & full docs:** https://github.com/hypernova2002/x-locality
**License:** MIT
**Backend image:** https://hub.docker.com/r/hypernova2002/x-locality-backend

## Quick start

Needs the [backend API image](https://hub.docker.com/r/hypernova2002/x-locality-backend) (or a compatible deployment of it) already running somewhere reachable:

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
