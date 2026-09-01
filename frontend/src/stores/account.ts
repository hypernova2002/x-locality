import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import * as accountApi from '@/api/account'
import type { Account } from '@/api/types'

export const useAccountStore = defineStore('account', () => {
  const account = ref<Account | null>(null)

  const timezone = computed(() => account.value?.timezone ?? 'UTC')

  async function load(token: string) {
    const { data } = await accountApi.getAccount(token)
    account.value = data
  }

  async function update(
    token: string,
    params: Partial<{
      name: string
      timezone: string
      logo_url: string | null
      correspondence_name: string | null
    }>,
  ) {
    const { data } = await accountApi.updateAccount(token, params)
    account.value = data
  }

  return { account, timezone, load, update }
})
