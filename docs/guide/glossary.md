# Glossary

The glossary holds **mandated term translations** that are applied automatically, every time a matching term appears in a translation request — no need to remember to tag anything. It's the right tool for:

- **Brand and product names** that should never be translated (e.g. "Acme Dashboard" should stay "Acme Dashboard" in every language).
- **Technical jargon** that an LLM might otherwise translate inconsistently from one request to the next.
- **Terms with one company-approved translation** for legal or marketing reasons.

<!-- screenshot: glossary list showing a mix of locale-specific and "all locales" entries -->

## Creating a term

Go to **Glossary** and click **New Term**, then fill in:

- **Source term** — the word or phrase to watch for, e.g. `workspace`.
- **Source language** — the language the source term itself is written in, e.g. `en`. Matching only happens against translation requests whose source text is in this same language.
- **Target term** — what it should become, e.g. `espace de travail`.
- **Target locale** — which locale this mapping applies to, e.g. `fr`. Choose **All locales** for terms that should never be translated at all (like a brand name) — the same target term is then used regardless of the target language.

You can have multiple entries for the same source term with different target locales, e.g. `workspace` → `espace de travail` for French and `workspace` → `Arbeitsbereich` for German.

## How matching works

When a translation is generated, XLocality checks the source text for any glossary term (same source language, and either matching the target locale or a wildcard "all locales" entry) and includes it in the prompt as a conditional instruction — "if relevant, translate X as Y." The LLM decides whether it actually applies, so an imperfect match is harmless; it's only a problem if a term that *should* apply gets missed, which matters more than an occasional over-match.

::: tip
Matching is plain substring matching, not word-boundary-anchored — this is deliberate. Many languages (Japanese, Chinese, Thai) don't use spaces between words, so a stricter match would silently fail to catch exactly the languages where getting this right matters most.
:::

## Export and import

Like locales and context tags, the glossary supports CSV/JSON export and import, with the same upsert-by-term semantics — useful for keeping a large glossary in a spreadsheet or version control and syncing it in bulk.
