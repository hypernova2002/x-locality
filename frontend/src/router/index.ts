import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { resolveLandingRoute } from '@/lib/landing'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/signup',
      name: 'signup',
      component: () => import('@/views/SignupView.vue'),
      meta: { guestOnly: true },
    },
    {
      path: '/accept-invite',
      name: 'accept-invite',
      component: () => import('@/views/AcceptInviteView.vue'),
    },
    {
      path: '/',
      component: () => import('@/components/AppShell.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'app-root',
          component: () => import('@/views/ProjectsListView.vue'),
          beforeEnter: async () => {
            const auth = useAuthStore()
            return resolveLandingRoute(auth.token!)
          },
        },
        {
          path: 'projects',
          name: 'projects',
          component: () => import('@/views/ProjectsListView.vue'),
        },
        {
          path: 'usage',
          name: 'account-usage',
          component: () => import('@/views/UsageView.vue'),
        },
        {
          path: 'account',
          name: 'account',
          component: () => import('@/views/AccountView.vue'),
        },
        {
          path: 'projects/:projectId',
          redirect: (to) => ({ name: 'project-translations', params: to.params }),
        },
        {
          path: 'projects/:projectId/settings',
          name: 'project-settings',
          component: () => import('@/views/ProjectSettingsView.vue'),
        },
        {
          path: 'projects/:projectId/locales',
          name: 'project-locales',
          component: () => import('@/views/LocalesView.vue'),
        },
        {
          path: 'projects/:projectId/context-tags',
          name: 'project-context-tags',
          component: () => import('@/views/ContextTagsView.vue'),
        },
        {
          path: 'projects/:projectId/glossary',
          name: 'project-glossary',
          component: () => import('@/views/GlossaryTermsView.vue'),
        },
        {
          path: 'projects/:projectId/translations',
          name: 'project-translations',
          component: () => import('@/views/TranslationsView.vue'),
        },
        {
          path: 'projects/:projectId/translations/:key',
          name: 'project-translation-detail',
          component: () => import('@/views/TranslationDetailView.vue'),
          props: (route) => ({ translationKey: route.params.key }),
        },
        {
          path: 'projects/:projectId/usage',
          name: 'project-usage',
          component: () => import('@/views/UsageView.vue'),
        },
      ],
    },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (to.meta.guestOnly && auth.isAuthenticated) {
    return resolveLandingRoute(auth.token!)
  }
})

export default router
