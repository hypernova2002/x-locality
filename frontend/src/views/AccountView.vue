<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Card from 'openvue/card'
import InputText from 'openvue/inputtext'
import Select from 'openvue/select'
import Button from 'openvue/button'
import Tag from 'openvue/tag'
import Message from 'openvue/message'
import ProgressSpinner from 'openvue/progressspinner'
import Tabs from 'openvue/tabs'
import TabList from 'openvue/tablist'
import Tab from 'openvue/tab'
import TabPanels from 'openvue/tabpanels'
import TabPanel from 'openvue/tabpanel'
import { useToast } from 'openvue/usetoast'
import { useConfirm } from 'openvue/useconfirm'
import { DateTime } from 'luxon'
import { getCountry, getAllTimezones } from 'countries-and-timezones'
import { useAuthStore } from '@/stores/auth'
import { useAccountStore } from '@/stores/account'
import * as accountApi from '@/api/account'
import { ApiError } from '@/api/client'
import type { AccountUser } from '@/api/types'

const auth = useAuthStore()
const accountStore = useAccountStore()
const router = useRouter()
const toast = useToast()
const confirm = useConfirm()
const { t } = useI18n()

const activeTab = ref('branding')
const isOwner = () => auth.user?.role === 'owner'

// countries-and-timezones supplies the IANA zone <-> country mapping (not
// something Intl exposes) so the picker can be searched by country name,
// not just the zone's city name. The offset itself is computed live via
// Luxon instead of the package's static data, so DST is always correct for
// right now rather than whatever was true when the package was published.
const timezoneOptions = Object.values(getAllTimezones())
  .filter((tz) => !tz.deprecated && !tz.aliasOf)
  .map((tz) => {
    const countryNames = tz.countries.map((code) => getCountry(code)?.name).filter(Boolean)
    const offset = DateTime.now().setZone(tz.name).toFormat('ZZ')
    return {
      label: `${tz.name} (UTC${offset})`,
      value: tz.name,
      searchText: `${tz.name} ${countryNames.join(' ')}`,
    }
  })
  .sort((a, b) => a.value.localeCompare(b.value))
const timezone = ref(accountStore.timezone)
const timezoneSaving = ref(false)

// The account store loads asynchronously (in AppShell), so this view can
// mount before it resolves - keep the select in sync once it does.
watch(
  () => accountStore.timezone,
  (tz) => {
    timezone.value = tz
  },
)

async function handleTimezoneChange(newTimezone: string) {
  timezoneSaving.value = true
  try {
    await accountStore.update(auth.token!, { timezone: newTimezone })
    toast.add({ severity: 'success', summary: t('account.timezoneCard.savedToast'), life: 2000 })
  } catch (e) {
    timezone.value = accountStore.timezone
    toast.add({
      severity: 'error',
      summary: e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong'),
      life: 4000,
    })
  } finally {
    timezoneSaving.value = false
  }
}

// --- branding: name, logo, correspondence name ---
const brandName = ref('')
const logoUrl = ref('')
const correspondenceName = ref('')
const brandingError = ref<string | null>(null)
const brandingSaving = ref(false)

watch(
  () => accountStore.account,
  (account) => {
    if (!account) return
    brandName.value = account.name
    logoUrl.value = account.logo_url ?? ''
    correspondenceName.value = account.correspondence_name ?? ''
  },
  { immediate: true },
)

async function handleSaveBranding() {
  brandingError.value = null
  brandingSaving.value = true
  try {
    await accountStore.update(auth.token!, {
      name: brandName.value,
      logo_url: logoUrl.value || null,
      correspondence_name: correspondenceName.value || null,
    })
    toast.add({ severity: 'success', summary: t('account.brandingCard.savedToast'), life: 2000 })
  } catch (e) {
    brandingError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    brandingSaving.value = false
  }
}

const users = ref<AccountUser[]>([])
const usersLoading = ref(true)

async function loadUsers() {
  usersLoading.value = true
  const { data } = await accountApi.listAccountUsers(auth.token!)
  users.value = data
  usersLoading.value = false
}

onMounted(loadUsers)

async function doRemoveUser(user: AccountUser) {
  await accountApi.deleteAccountUser(auth.token!, user.id)
  toast.add({ severity: 'success', summary: t('account.usersCard.removedToast'), life: 3000 })
  await loadUsers()
}

function handleRemoveUser(event: Event, user: AccountUser) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('account.usersCard.removeConfirm', { email: user.email }),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('account.usersCard.remove'), severity: 'danger' },
    accept: () => doRemoveUser(user),
  })
}

// --- transfer ownership ---
const transferEmail = ref('')
const transferError = ref<string | null>(null)
const transferring = ref(false)

async function doTransfer() {
  transferring.value = true
  try {
    await accountApi.transferOwnership(auth.token!, transferEmail.value)
    toast.add({ severity: 'success', summary: t('account.transferCard.transferredToast'), life: 3000 })
    auth.updateUser({ role: 'member' })
    transferEmail.value = ''
    await loadUsers()
  } catch (e) {
    transferError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    transferring.value = false
  }
}

function handleTransfer(event: Event) {
  transferError.value = null
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('account.transferCard.confirm', { email: transferEmail.value }),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('account.transferCard.submit'), severity: 'danger' },
    accept: doTransfer,
  })
}

// --- delete account ---
const deleting = ref(false)

async function doDeleteAccount() {
  deleting.value = true
  try {
    await accountApi.deleteAccount(auth.token!)
    auth.logout()
    router.push({ name: 'login' })
  } finally {
    deleting.value = false
  }
}

function handleDeleteAccount(event: Event) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('account.dangerCard.deleteConfirm'),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('account.dangerCard.deleteButton'), severity: 'danger' },
    accept: doDeleteAccount,
  })
}
</script>

<template>
  <div class="flex max-w-2xl flex-col gap-6">
    <Tabs v-model:value="activeTab">
      <TabList>
        <Tab value="branding">{{ t('account.tabs.branding') }}</Tab>
        <Tab value="timezone">{{ t('account.tabs.timezone') }}</Tab>
        <Tab value="users">{{ t('account.tabs.users') }}</Tab>
        <Tab v-if="isOwner()" value="danger">{{ t('account.tabs.danger') }}</Tab>
      </TabList>
      <TabPanels>
    <TabPanel value="branding">
    <Card>
      <template #title>{{ t('account.brandingCard.cardTitle') }}</template>
      <template #content>
        <form class="flex flex-col gap-4" @submit.prevent="handleSaveBranding">
          <Message v-if="brandingError" severity="error" :closable="false">{{ brandingError }}</Message>

          <div class="flex flex-col gap-2">
            <label for="brand-name" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('account.brandingCard.name')
            }}</label>
            <InputText id="brand-name" v-model="brandName" fluid />
          </div>

          <div class="flex flex-col gap-2">
            <label for="logo-url" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('account.brandingCard.logoUrl')
            }}</label>
            <div class="flex items-center gap-3">
              <img
                :src="logoUrl || '/xlocality-logo.svg'"
                alt=""
                class="h-10 w-10 shrink-0 rounded-md object-contain"
              />
              <InputText
                id="logo-url"
                v-model="logoUrl"
                :placeholder="t('account.brandingCard.logoUrlPlaceholder')"
                fluid
              />
            </div>
            <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('account.brandingCard.logoUrlHint') }}</p>
          </div>

          <div class="flex flex-col gap-2">
            <label for="correspondence-name" class="text-sm font-medium text-[var(--p-text-color)]">{{
              t('account.brandingCard.correspondenceName')
            }}</label>
            <InputText
              id="correspondence-name"
              v-model="correspondenceName"
              :placeholder="brandName"
              fluid
            />
            <p class="text-xs text-[var(--p-text-muted-color)]">
              {{ t('account.brandingCard.correspondenceNameHint') }}
            </p>
          </div>

          <Button
            type="submit"
            :label="t('account.brandingCard.save')"
            :loading="brandingSaving"
            class="self-start"
          />
        </form>
      </template>
    </Card>
    </TabPanel>

    <TabPanel value="timezone">
    <Card>
      <template #title>{{ t('account.timezoneCard.cardTitle') }}</template>
      <template #content>
        <div class="flex flex-col gap-2">
          <label for="timezone" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('account.timezoneCard.label')
          }}</label>
          <Select
            id="timezone"
            v-model="timezone"
            :options="timezoneOptions"
            option-label="label"
            option-value="value"
            filter
            :filter-fields="['searchText']"
            :loading="timezoneSaving"
            fluid
            @update:model-value="handleTimezoneChange"
          />
          <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('account.timezoneCard.hint') }}</p>
        </div>
      </template>
    </Card>
    </TabPanel>

    <TabPanel value="users">
    <Card>
      <template #title>{{ t('account.usersCard.cardTitle') }}</template>
      <template #content>
        <div v-if="usersLoading" class="flex justify-center py-8">
          <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
        </div>

        <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
          <div
            v-for="user in users"
            :key="user.id"
            class="flex min-w-0 items-center gap-3 py-3 first:pt-0 last:pb-0"
          >
            <span class="min-w-0 flex-1 truncate text-sm text-[var(--p-text-color)]">{{ user.email }}</span>
            <Tag
              :value="user.role"
              :severity="user.role === 'owner' ? 'success' : 'secondary'"
              class="shrink-0"
            />
            <Button
              v-if="isOwner() && user.role !== 'owner'"
              icon="oi oi-trash"
              text
              size="small"
              severity="danger"
              class="shrink-0"
              @click="(e: Event) => handleRemoveUser(e, user)"
            />
          </div>
        </div>
      </template>
    </Card>
    </TabPanel>

    <TabPanel v-if="isOwner()" value="danger">
      <div class="flex flex-col gap-6">
      <Card>
        <template #title>{{ t('account.transferCard.cardTitle') }}</template>
        <template #content>
          <form class="flex flex-col gap-4" @submit.prevent="handleTransfer">
            <Message v-if="transferError" severity="error" :closable="false">{{ transferError }}</Message>
            <p class="text-sm text-[var(--p-text-muted-color)]">{{ t('account.transferCard.description') }}</p>
            <div class="flex flex-col gap-2">
              <label for="transfer-email" class="text-sm font-medium text-[var(--p-text-color)]">{{
                t('account.transferCard.email')
              }}</label>
              <InputText id="transfer-email" v-model="transferEmail" type="email" fluid />
            </div>
            <Button
              type="submit"
              :label="t('account.transferCard.submit')"
              severity="danger"
              :loading="transferring"
              class="self-start"
            />
          </form>
        </template>
      </Card>

      <Card>
        <template #title>{{ t('account.dangerCard.cardTitle') }}</template>
        <template #content>
          <p class="mb-4 text-sm text-[var(--p-text-muted-color)]">{{ t('account.dangerCard.description') }}</p>
          <Button
            :label="t('account.dangerCard.deleteButton')"
            severity="danger"
            :loading="deleting"
            @click="handleDeleteAccount"
          />
        </template>
      </Card>
      </div>
    </TabPanel>
      </TabPanels>
    </Tabs>
  </div>
</template>
