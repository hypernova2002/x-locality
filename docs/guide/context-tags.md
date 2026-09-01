# Context tags

A context tag is a short label with a description that you attach to a specific translation request to disambiguate the source text — for example, telling the LLM that "fruit" in this particular string refers to the food, not the company.

<!-- screenshot: context tags list -->

## Creating a tag

Go to **Context Tags** and click **New Tag**. Give it a short **key** (e.g. `fruit`) and a **description** explaining what it means (e.g. "Use when the source word refers to fruit, not a company/brand"). The description is what actually gets included in the LLM prompt, so make it clear and specific.

## Using a tag

Context tags are attached per translation request via the `context` field when calling the API (see [API access](/guide/api-access)) — they aren't something you apply retroactively from the admin UI. A request can attach multiple tags to the same item.

## Context tags vs. glossary

Context tags are a **hint** you apply deliberately, per key, to help the LLM disambiguate — they don't force a specific translation. If you need a term translated the *same way, every time it appears*, without having to remember to tag it — a brand name, a piece of jargon with one approved translation — that's what the [Glossary](/guide/glossary) is for instead.

## Editing or deleting

Renaming a tag's key doesn't retroactively change past translations — it only affects future requests that reference the new key. Deleting a tag removes the association from any translations that used it, but doesn't undo anything the LLM already generated.
