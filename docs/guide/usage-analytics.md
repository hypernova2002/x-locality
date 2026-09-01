# Usage & analytics

The **Usage** page (per project, and account-wide from the top-right menu) has three tabs.

<!-- screenshot: usage page with API/LLM/Translations tabs -->

## API

Requests made against the translation API — total, successful vs. failed, and translations performed, with a day-by-day chart. Useful for spotting integration problems (a spike in failed requests) or unexpected traffic.

## LLM

Actual LLM provider calls — input/output tokens, estimated cost, average latency, and success/failure counts, broken down by provider and model. This is where to look if you want to understand what your LLM bill is actually made of, or compare latency/cost across models you've tried.

## Translations

How many times translations were requested, and the split between **cache hits** (served instantly, no LLM cost) and **LLM generations** (a fresh call was needed) — with a day-by-day chart of the same breakdown. This tab only appears at the project level, since it's inherently about one project's content.

A high cache-hit rate generally means your application is requesting the same, unchanged keys repeatedly (expected and good — that's what the cache is for). A low rate on an established project can be a sign that source text is changing more than expected, or that keys are being regenerated unnecessarily.

### Per-key usage

The **Translations** list itself also shows this, per key: a small badge with a chart icon and a request count next to any key that's actually been requested (hover it for the cache/generation split), plus a project-wide total at the top of the page. The translation detail page shows the same breakdown per locale.
