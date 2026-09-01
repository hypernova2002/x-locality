import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import * as authApi from '@/api/auth'
import * as invitesApi from '@/api/invites'
import type { User } from '@/api/types'

const STORAGE_KEY = 'x-locality:auth'

interface StoredAuth {
  token: string
  user: User
}

function loadStoredAuth(): StoredAuth | null {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as StoredAuth
  } catch {
    return null
  }
}

export const useAuthStore = defineStore('auth', () => {
  const stored = loadStoredAuth()
  const token = ref<string | null>(stored?.token ?? null)
  const user = ref<User | null>(stored?.user ?? null)

  const isAuthenticated = computed(() => token.value !== null)

  function persist() {
    if (token.value && user.value) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ token: token.value, user: user.value }))
    } else {
      localStorage.removeItem(STORAGE_KEY)
    }
  }

  async function login(params: { email: string; password: string }) {
    const { data } = await authApi.login(params)
    token.value = data.access_token
    user.value = data.user
    persist()
  }

  async function signup(params: { account_name: string; email: string; password: string }) {
    const { data } = await authApi.signup(params)
    token.value = data.access_token
    user.value = data.user
    persist()
  }

  async function acceptInvite(inviteToken: string, password: string) {
    const { data } = await invitesApi.acceptInvite(inviteToken, password)
    token.value = data.access_token
    user.value = data.user
    persist()
  }

  function updateUser(patch: Partial<User>) {
    if (!user.value) return
    user.value = { ...user.value, ...patch }
    persist()
  }

  function logout() {
    token.value = null
    user.value = null
    persist()
  }

  return { token, user, isAuthenticated, login, signup, acceptInvite, updateUser, logout }
})
