# Account & team

## Roles

- **Owner** — one per account, the only user who can transfer ownership or delete the account entirely.
- **Project admin** — full access to a specific project, including its Settings (LLM config, API keys, webhooks) and Members.
- **Project member** — can view and edit translations but can't change project settings, and doesn't see the Members list.

Project access is per-project membership, not account-wide — someone can be an admin on one project and have no access at all to another, even on the same account.

## Inviting someone

From a project's **Settings → Members**, click **Add member**, enter their email, and choose a role. If they don't already have an account, they receive an email invite; accepting it creates their account and adds them to the project in one step.

<!-- screenshot: members list with pending invites -->

## Account settings

Reached from the menu in the top-right corner. It's split into a few tabs:

- **Branding** — set your account name, a logo URL, and an email "correspondence name" used as the sender identity on outgoing emails (invites, budget alerts). Leave the logo blank to use the default.
- **Timezone** — the display timezone used throughout the app for showing dates/times. Everything is stored in UTC internally and converted for display, so changing this doesn't affect any data, only how it's shown to you.
- **Users** — everyone on the account, with the ability to remove non-owner users.
- **Danger Zone** *(owner only)* — transfer ownership to another user on the account, or permanently delete the account and everything in it.

<!-- screenshot: account settings branding tab -->

## Dark mode

Toggle light/dark from the account menu in the top-right corner. Your choice is remembered per browser.
