# Getting started

x-locality organizes work into **accounts**, **projects**, and **locales**:

- An **account** is your organization. It holds billing/branding settings, team members, and one or more projects.
- A **project** is a single translatable product or app — most teams create one project per app they're localizing.
- A **locale** is a target language within a project (e.g. `fr`, `de`, `pt-BR`).

## Creating an account

Sign up from the login screen with your email and a password. The first user on an account is its **owner** — the only role that can delete the account or transfer ownership to someone else.

<!-- screenshot: signup form -->

## Creating your first project

From the **Projects** page, click **New Project** and give it a name. You'll land on the project's **Translations** page, which is empty until you add locales and start translating.

<!-- screenshot: projects list with "New Project" button -->

Every new project seeds a set of standard ISO locales automatically (see [Locales](/guide/locales)), so you can usually start translating without creating a locale yourself.

## Configuring an LLM provider

Before you can generate any translations, the project needs an LLM provider configured — go to **Settings → LLM** and see [LLM configuration](/guide/llm-configuration).

## The sidebar

Once inside a project, the left sidebar has:

- **Translations** — the main working view: every translation key, its status per locale, and search/filters.
- **Locales** — the target languages for this project.
- **Context Tags** — reusable hints you can attach to ambiguous source text.
- **Glossary** — mandated term translations (brand names, jargon) applied automatically.
- **Usage** — API, LLM, and translation request analytics.
- **Settings** — LLM provider, budget alerts, API keys, webhooks, and members (admins only).

Your account-level pages (Usage, Account settings) are reached from the menu in the top-right corner, next to the project switcher.

<!-- screenshot: sidebar with nav items labeled -->
