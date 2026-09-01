# Webhooks

Webhooks notify a URL you control when something happens in a project, instead of you having to poll the API or watch your inbox. They're managed under **Settings → Webhooks**.

<!-- screenshot: webhooks list with event type tags -->

## Events

Two events are currently available:

- **Translation batch completed** — fires after any translation request finishes (whether triggered externally via the API or by an admin action like regenerate or bulk translate), with a summary of how many translations succeeded and failed.
- **Budget threshold crossed** — fires the first time usage crosses your configured alert threshold in a month, alongside the existing email alert.

## Adding a webhook

Click **New Webhook**, enter the URL to deliver to, and tick the event types you want to receive. A random secret is generated automatically — you'll need it to verify deliveries (see below).

## Verifying deliveries

Every delivery is a `POST` request with a JSON body and two headers:

- `X-Webhook-Event` — the event type, e.g. `translation.batch_completed`.
- `X-Webhook-Signature` — `sha256=<hex-encoded HMAC-SHA256 of the raw request body, using your webhook's secret>`.

Recompute the HMAC on your end with the same secret and compare it to the header before trusting the payload — this confirms the request actually came from XLocality and wasn't forged or tampered with in transit.

## Testing and debugging

Use **Send test** on a webhook to trigger an immediate delivery with a sample payload and see right away whether your endpoint is reachable. Click **Deliveries** on any webhook to see its recent delivery history — event type, success/failure, HTTP status, and any error message, which is the first place to look if deliveries seem to be failing silently.

Failed deliveries are retried automatically; each attempt (not just the final outcome) is recorded in the delivery history.

## Disabling without deleting

Toggle a webhook off rather than deleting it if you want to pause deliveries temporarily without losing its configuration and secret.
