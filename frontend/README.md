# Frontend

Vue 3 admin UI — Vite, TypeScript, Pinia, vue-router, and an [openvue](https://www.npmjs.com/package/openvue) component library (a PrimeVue-v4-compatible set of components). See the [root README](../README.md) for setup and running the full stack — everything here runs via `docker compose`, not host `npm`.

## Structure

```
frontend/
  src/
    api/            # One file per resource - thin wrappers around fetch calls to the Hanami admin API
    components/     # Shared components used across multiple views (AppShell, EmptyState, ...)
    composables/    # Shared reactive logic (useProject, ...)
    i18n/           # vue-i18n - all UI strings live in i18n/locales/en.json, not inline in components
    lib/            # Framework-agnostic helpers (base64, date formatting, localStorage helpers)
    router/         # vue-router routes
    stores/         # Pinia stores (auth, account, theme)
    views/          # One file per route/page
```

## Conventions

- All user-facing text goes through `i18n/locales/en.json` (`t('...')`), even though only English exists today — keeps strings out of component logic.
- `dt()`-style semantic CSS custom properties (`--p-text-color`, `--p-content-background`, etc.) for anything that needs to adapt to light/dark mode, rather than hardcoded colors.
- API calls go through `src/api/*.ts`, never `fetch` directly in a component/view.

## Linting

`npm run lint` (oxlint + eslint) runs automatically on staged files via the repo's Lefthook pre-commit hook (see root README). Run it manually with:

```bash
docker compose run --rm web npm run lint
```

Type-check with:

```bash
docker compose run --rm web npm run type-check
```
