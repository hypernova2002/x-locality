<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Card from 'openvue/card'
import InputText from 'openvue/inputtext'
import Password from 'openvue/password'
import Button from 'openvue/button'
import Message from 'openvue/message'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/api/client'
import { resolveLandingRoute } from '@/lib/landing'

const auth = useAuthStore()
const router = useRouter()
const { t } = useI18n()

const accountName = ref('')
const email = ref('')
const password = ref('')
const error = ref<string | null>(null)
const submitting = ref(false)

async function handleSubmit() {
  error.value = null
  submitting.value = true
  try {
    await auth.signup({
      account_name: accountName.value,
      email: email.value,
      password: password.value,
    })
    router.push(await resolveLandingRoute(auth.token!))
  } catch (e) {
    error.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="flex h-full items-center justify-center bg-[var(--app-canvas)]">
    <Card class="w-full max-w-sm">
      <template #title>{{ t('auth.signup.title') }}</template>
      <template #content>
        <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
          <Message v-if="error" severity="error" :closable="false">{{ error }}</Message>

          <div class="flex flex-col gap-2">
            <label for="account-name" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('auth.signup.accountName')
            }}</label>
            <InputText
              id="account-name"
              v-model="accountName"
              :placeholder="t('auth.signup.accountNamePlaceholder')"
              fluid
            />
          </div>

          <div class="flex flex-col gap-2">
            <label for="email" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('auth.signup.email')
            }}</label>
            <InputText id="email" v-model="email" placeholder="you@example.com" fluid />
          </div>

          <div class="flex flex-col gap-2">
            <label for="password" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('auth.signup.password')
            }}</label>
            <Password
              id="password"
              v-model="password"
              :placeholder="t('auth.signup.passwordPlaceholder')"
              :feedback="false"
              toggle-mask
              fluid
            />
          </div>

          <Button type="submit" :label="t('auth.signup.submit')" :loading="submitting" fluid />
        </form>
      </template>
      <template #footer>
        <span class="text-sm text-[var(--p-text-muted-color)]">
          {{ t('auth.signup.haveAccount') }}
          <RouterLink to="/login" class="text-[var(--p-primary-color)]">{{
            t('auth.signup.logIn')
          }}</RouterLink>
        </span>
      </template>
    </Card>
  </div>
</template>
