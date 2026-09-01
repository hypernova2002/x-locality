# API access

Applications integrate with x-locality through a separate, API-key-authenticated API — distinct from the admin UI you use in the browser, which is authenticated by your login session instead.

## Creating an API key

Go to **Settings → API Keys** and click **New API Key**. Give it a descriptive name (e.g. `production`, `ci`) — the key itself is shown once at creation and can be revealed again from the list, copied, revoked, or deleted at any time. Revoking stops it working immediately; deleting removes it entirely.

<!-- screenshot: API keys list with reveal/copy controls -->

## Authenticating requests

Every request needs the key in an `Authorization: Bearer` header:

```bash
curl https://your-x-locality-instance/api/v1/translations \
  -H "Authorization: Bearer <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

The key identifies which project the request belongs to — there's no separate project ID to pass.

## Requesting translations

```bash
curl -X POST https://your-x-locality-instance/api/v1/translations \
  -H "Authorization: Bearer <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "target_locales": ["fr", "de"],
    "items": [
      {
        "key": "welcome_message",
        "source_text": "Welcome to your workspace",
        "source_language": "en",
        "context": ["ui_label"]
      }
    ]
  }'
```

For each item and locale, this returns immediately from cache if an unchanged, completed translation already exists, or generates a fresh one via the LLM otherwise — see [Translations](/guide/translations) for how the cache works. `context` is optional and references [context tag](/guide/context-tags) keys that already exist in the project.

## Fetching translations

```bash
curl "https://your-x-locality-instance/api/v1/translations?locale=fr" \
  -H "Authorization: Bearer <your-api-key>"
```

Returns a flat, paginated list of translations — filter by `locale` and/or `key`, and follow the `Link` response header for the next page. `GET /api/v1/translations/:key` fetches a single key across all locales.

## Rate limits and errors

Errors follow [RFC 9457 Problem Details](https://www.rfc-editor.org/rfc/rfc9457) — a JSON body with `type`, `title`, `status`, and usually `detail`. A `402` means the project's monthly budget limit has been reached; a `422` means validation failed (check `errors` in the body for field-level detail).
