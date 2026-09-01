import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'x-locality',
  description: 'User guide for x-locality, the translation management platform.',

  // GitHub Pages project sites are served at https://<org>.github.io/<repo>/,
  // so this must match your actual repo name once one exists. Set to '/' if
  // you deploy to a custom domain or a github.io *user/org* page instead of
  // a project page.
  base: '/x-locality/',

  cleanUrls: true,

  head: [['link', { rel: 'icon', href: '/x-locality/favicon.svg' }]],

  themeConfig: {
    logo: '/favicon.svg',

    nav: [
      { text: 'Guide', link: '/guide/getting-started' },
    ],

    sidebar: [
      {
        text: 'Introduction',
        items: [{ text: 'Getting started', link: '/guide/getting-started' }],
      },
      {
        text: 'Content',
        items: [
          { text: 'Projects', link: '/guide/projects' },
          { text: 'Locales', link: '/guide/locales' },
          { text: 'Translations', link: '/guide/translations' },
          { text: 'Context tags', link: '/guide/context-tags' },
          { text: 'Glossary', link: '/guide/glossary' },
          { text: 'Bulk operations', link: '/guide/bulk-operations' },
        ],
      },
      {
        text: 'LLM & automation',
        items: [
          { text: 'LLM configuration', link: '/guide/llm-configuration' },
          { text: 'Usage & analytics', link: '/guide/usage-analytics' },
          { text: 'Webhooks', link: '/guide/webhooks' },
        ],
      },
      {
        text: 'Integrating',
        items: [{ text: 'API access', link: '/guide/api-access' }],
      },
      {
        text: 'Account & team',
        items: [{ text: 'Account & team', link: '/guide/account-and-team' }],
      },
    ],

    search: { provider: 'local' },

    socialLinks: [],

    footer: {
      message: 'x-locality user guide',
    },
  },
})
