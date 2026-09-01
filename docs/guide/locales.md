# Locales

A locale is one target language within a project. Every new project is seeded with a set of standard **system locales** (the common ISO languages) — these are read-only (you can't edit or delete them), but you can translate into them like any other locale.

<!-- screenshot: locales list showing system and custom locales -->

## Adding a custom locale

Click **New Locale** and fill in:

- **Key** — a short identifier, e.g. `fr-casual` for an informal French variant distinct from standard `fr`.
- **Target language** — the actual language code the LLM should translate into, e.g. `fr`.
- **Style / tone** (optional) — free text guidance like "Casual, friendly" that's included in every generation prompt for this locale.
- **Description** (optional) — internal notes about when to use this locale.

Custom locales are useful when you need more than one variant of the same underlying language — a formal and an informal French, for instance — since the `key` is what your translation requests target, while `target_language` and the style/tone guidance shape how the LLM actually writes it.

## Editing or deleting a locale

Non-system locales can be edited or deleted from the list. Deleting a locale removes every translation that exists for it — this can't be undone.

## Exporting and importing locales

Use **Export** to download all locales as CSV or JSON (gzip-compressed), and **Import** to bulk-create or update locales from a file in the same format. Re-importing an unmodified export is a no-op. System locales are protected on import — a row matching an existing system locale is skipped, never overwritten.

<!-- screenshot: import modal with file picker -->

## Bulk translating into a locale

To generate translations for every key that's missing one in a given locale, use the **Bulk translate** action on that locale's row — see [Bulk operations](/guide/bulk-operations).
