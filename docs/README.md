# x-locality docs

The user guide, built with [VitePress](https://vitepress.dev). Source pages are plain Markdown under `guide/`.

## Local development

From the repo root, with the stack up:

```bash
docker compose up docs
```

Then open `http://localhost:5174` — pages live-reload as you edit.

Without the rest of the stack running, you can also run it standalone:

```bash
docker compose run --rm --service-ports docs
```

## Adding a page

1. Create a new `.md` file under `guide/`.
2. Add it to the `sidebar` (and `nav`, if it's a top-level section) in `.vitepress/config.mts`.

## Adding screenshots

Save images under `public/screenshots/` (PNG or WebP), then reference them with a normal Markdown image, e.g.:

```md
![Locales list](/screenshots/locales-list.png)
```

Paths starting with `/` are resolved relative to `public/`, not the current page.

Every guide page has `<!-- screenshot: ... --> ` placeholder comments marking where a screenshot would help — search for `screenshot:` across `guide/` to find them all. Replace each comment with the actual image once you have it; the comments themselves don't render, so it's safe to leave any of them in place if you don't have that screenshot yet.

## Building

```bash
docker compose run --rm docs npm run build
```

Output goes to `.vitepress/dist/`, matching what the GitHub Actions deploy workflow builds and publishes.

## Deployment

Pushing to `main` with changes under `docs/` triggers `.github/workflows/deploy-docs.yml`, which builds the site and publishes it to GitHub Pages. This requires Pages to be enabled for the repo once (**Settings → Pages → Source: GitHub Actions**), and the `base` path in `.vitepress/config.mts` to match your actual repo name (`/<repo>/` for a project page, or `/` for a custom domain / user-org page).
