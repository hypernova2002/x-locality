# LLM configuration

A project needs an LLM provider configured before it can generate any translations. This lives under **Settings**, split across a few tabs.

## LLM provider configs

Under **Settings → LLM Providers**, you can save multiple provider/model/API-key combinations for a project and switch which one is active without re-entering credentials each time — useful for keeping a cheaper model around alongside a higher-quality one, or switching providers without losing your saved configuration.

Click **New Config**, choose a provider, paste credentials, and (where applicable) use **Fetch models** to pull the list of models actually available to them. Give the config a name so it's identifiable in the list (e.g. "Prod Anthropic key").

Anthropic, OpenAI, and Gemini take a single API key. Amazon Bedrock and Amazon Translate are AWS services, so they instead take an access key ID, secret access key, and region.

Amazon Translate is a plain translation service, not an LLM — it's typically cheaper and faster, but it can't take glossary terms or context tags into account the way the other providers can, since those work by adding instructions to a prompt and Translate has no prompt. It also has no models to choose from, so the model field doesn't apply to it.

<!-- screenshot: LLM provider config list with active badge -->

Only one config is active per project at a time — switch it from the list with **Set active**, no need to re-enter the API key.

## Budgets and alerts

Under **Settings → LLM**, set an optional **monthly cost limit** and/or **monthly token limit**. Once either is reached, further translation generation is blocked until the next calendar month (existing cached translations still work). Set an **alert email** and a **threshold percentage** to get a warning email the first time usage crosses that percentage in a month, ahead of the hard limit — use **Send test alert** to confirm delivery without waiting for real usage.

<!-- screenshot: budget limit and alert threshold fields -->

## Langfuse tracing

If your self-hosted [Langfuse](https://langfuse.com) instance is available, enable **Trace LLM calls in Langfuse** in the same LLM settings tab and paste in a public/secret key pair from your Langfuse project. Every translation call — model, input, output, tokens, latency, and cost — is then sent to Langfuse as a trace, useful for debugging quality issues or reviewing exactly what was sent to the model.

This is entirely optional; leaving it disabled has no effect on translation generation itself.
