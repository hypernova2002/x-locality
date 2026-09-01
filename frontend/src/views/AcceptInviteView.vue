<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Card from 'openvue/card'
import Password from 'openvue/password'
import Button from 'openvue/button'
import Message from 'openvue/message'
import ProgressSpinner from 'openvue/progressspinner'
import { useAuthStore } from '@/stores/auth'
import * as invitesApi from '@/api/invites'
import { ApiError } from '@/api/client'
import { resolveLandingRoute } from '@/lib/landing'
import type { InvitePreview } from '@/api/types'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const { t } = useI18n()

const token = route.query.token as string | undefined

const preview = ref<InvitePreview | null>(null)
const previewError = ref<string | null>(null)
const loading = ref(true)

async function loadPreview() {
  if (!token) {
    previewError.value = t('common.somethingWentWrong')
    loading.value = false
    return
  }
  loading.value = true
  try {
    const { data } = await invitesApi.previewInvite(token)
    preview.value = data
  } catch (e) {
    previewError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    loading.value = false
  }
}

onMounted(loadPreview)

const password = ref('')
const submitError = ref<string | null>(null)
const submitting = ref(false)

async function handleSubmit() {
  if (!token) return
  submitError.value = null
  submitting.value = true
  try {
    await auth.acceptInvite(token, password.value)
    router.push(await resolveLandingRoute(auth.token!))
  } catch (e) {
    submitError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="flex h-full items-center justify-center bg-[var(--app-canvas)]">
    <Card class="w-full max-w-sm">
      <template #title>{{ t('acceptInvite.title') }}</template>
      <template #content>
        <div v-if="loading" class="flex justify-center py-8">
          <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
        </div>

        <div v-else-if="previewError">
          <Message severity="error" :closable="false">{{ previewError }}</Message>
          <RouterLink to="/login" class="mt-4 block text-sm text-[var(--p-primary-color)]">{{
            t('acceptInvite.goToLogin')
          }}</RouterLink>
        </div>

        <form v-else-if="preview" class="flex flex-col gap-4" @submit.prevent="handleSubmit">
          <Message v-if="submitError" severity="error" :closable="false">{{ submitError }}</Message>

          <p class="text-sm text-[var(--p-text-color)]">
            {{ t('acceptInvite.invitedTo', { project: preview.project_name, role: preview.role }) }}
            <template v-if="preview.invited_by_email">{{
              t('acceptInvite.invitedBy', { email: preview.invited_by_email })
            }}</template>
          </p>

          <div class="flex flex-col gap-2">
            <label for="password" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('acceptInvite.password')
            }}</label>
            <Password
              id="password"
              v-model="password"
              :placeholder="t('acceptInvite.passwordPlaceholder')"
              :feedback="false"
              toggle-mask
              fluid
            />
          </div>

          <Button type="submit" :label="t('acceptInvite.submit')" :loading="submitting" fluid />
        </form>
      </template>
    </Card>
  </div>
</template>
