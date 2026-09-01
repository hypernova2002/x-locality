<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import Card from 'openvue/card'
import Button from 'openvue/button'
import Dialog from 'openvue/dialog'
import InputText from 'openvue/inputtext'
import Select from 'openvue/select'
import Tag from 'openvue/tag'
import Message from 'openvue/message'
import ProgressSpinner from 'openvue/progressspinner'
import EmptyState from '@/components/EmptyState.vue'
import { useToast } from 'openvue/usetoast'
import { useConfirm } from 'openvue/useconfirm'
import { useAuthStore } from '@/stores/auth'
import { useProject } from '@/composables/useProject'
import * as membersApi from '@/api/members'
import * as invitesApi from '@/api/invites'
import { ApiError } from '@/api/client'
import type { Invite, ProjectMember, ProjectRole } from '@/api/types'

const auth = useAuthStore()
const toast = useToast()
const confirm = useConfirm()
const { t } = useI18n()
const { project } = useProject()

const isAdmin = () => project.value?.my_role === 'admin'

const members = ref<ProjectMember[]>([])
const membersLoading = ref(true)
const invites = ref<Invite[]>([])
const invitesLoading = ref(true)

async function loadMembers() {
  membersLoading.value = true
  const { data } = await membersApi.listMembers(auth.token!, project.value!.id)
  members.value = data
  membersLoading.value = false
}

async function loadInvites() {
  if (!isAdmin()) {
    invitesLoading.value = false
    return
  }
  invitesLoading.value = true
  const { data } = await invitesApi.listInvites(auth.token!, project.value!.id)
  invites.value = data
  invitesLoading.value = false
}

onMounted(() => {
  loadMembers()
  loadInvites()
})

const roleOptions = computed<{ label: string; value: ProjectRole }[]>(() => [
  { label: t('members.roleAdmin'), value: 'admin' },
  { label: t('members.roleMember'), value: 'member' },
])

// --- add/invite ---
const showAddModal = ref(false)
const addEmail = ref('')
const addRole = ref<ProjectRole>('member')
const addError = ref<string | null>(null)
const adding = ref(false)

function openAddModal() {
  addEmail.value = ''
  addRole.value = 'member'
  addError.value = null
  showAddModal.value = true
}

async function handleAdd() {
  addError.value = null
  adding.value = true
  try {
    try {
      await membersApi.addMember(auth.token!, project.value!.id, { email: addEmail.value, role: addRole.value })
      toast.add({ severity: 'success', summary: t('members.addedToast'), life: 3000 })
      await loadMembers()
    } catch (e) {
      // No account user with this email yet - fall back to an email invite
      // rather than making the admin pick the flow up front.
      if (e instanceof ApiError && e.status === 404) {
        await invitesApi.createInvite(auth.token!, project.value!.id, {
          email: addEmail.value,
          role: addRole.value,
        })
        toast.add({ severity: 'success', summary: t('members.invitedToast'), life: 3000 })
        await loadInvites()
      } else {
        throw e
      }
    }
    showAddModal.value = false
  } catch (e) {
    addError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    adding.value = false
  }
}

// --- role change / remove ---
async function handleRoleChange(member: ProjectMember, role: ProjectRole) {
  await membersApi.updateMemberRole(auth.token!, project.value!.id, member.user_id, role)
  member.project_role = role
  toast.add({ severity: 'success', summary: t('members.roleUpdatedToast'), life: 2000 })
}

async function doRemoveMember(member: ProjectMember) {
  await membersApi.removeMember(auth.token!, project.value!.id, member.user_id)
  toast.add({ severity: 'success', summary: t('members.removedToast'), life: 3000 })
  await loadMembers()
}

function handleRemoveMember(event: Event, member: ProjectMember) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('members.removeConfirm', { email: member.email }),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('common.delete'), severity: 'danger' },
    accept: () => doRemoveMember(member),
  })
}

// --- cancel invite ---
async function doCancelInvite(invite: Invite) {
  await invitesApi.deleteInvite(auth.token!, project.value!.id, invite.id)
  toast.add({ severity: 'success', summary: t('members.invites.cancelledToast'), life: 3000 })
  await loadInvites()
}

function handleCancelInvite(event: Event, invite: Invite) {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: t('members.invites.cancelConfirm', { email: invite.email }),
    icon: 'oi oi-exclamation-triangle',
    rejectProps: { label: t('common.cancel'), severity: 'secondary', outlined: true },
    acceptProps: { label: t('members.invites.cancel'), severity: 'danger' },
    accept: () => doCancelInvite(invite),
  })
}
</script>

<template>
  <div class="flex flex-col gap-6">
    <Card>
      <template #title>
        <div class="flex items-center justify-between">
          <span>{{ t('members.cardTitle') }}</span>
          <Button v-if="isAdmin()" :label="t('members.addButton')" icon="oi oi-plus" size="small" @click="openAddModal" />
        </div>
      </template>
      <template #content>
        <div v-if="membersLoading" class="flex justify-center py-8">
          <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
        </div>

        <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
          <div
            v-for="member in members"
            :key="member.user_id"
            class="flex min-w-0 items-center gap-3 py-3 first:pt-0 last:pb-0"
          >
            <span class="min-w-0 flex-1 truncate text-sm text-[var(--p-text-color)]">{{ member.email }}</span>
            <Tag
              v-if="member.account_role === 'owner'"
              :value="t('members.owner')"
              severity="success"
              class="shrink-0"
            />
            <Select
              v-else-if="isAdmin()"
              :model-value="member.project_role"
              :options="roleOptions"
              option-label="label"
              option-value="value"
              class="shrink-0"
              style="width: 8rem"
              @update:model-value="(role: ProjectRole) => handleRoleChange(member, role)"
            />
            <Tag v-else :value="member.project_role" severity="secondary" class="shrink-0" />
            <Button
              v-if="isAdmin() && member.account_role !== 'owner'"
              icon="oi oi-trash"
              text
              size="small"
              severity="danger"
              class="shrink-0"
              @click="(e: Event) => handleRemoveMember(e, member)"
            />
          </div>
        </div>
      </template>
    </Card>

    <Card v-if="isAdmin()">
      <template #title>{{ t('members.invites.cardTitle') }}</template>
      <template #content>
        <div v-if="invitesLoading" class="flex justify-center py-8">
          <ProgressSpinner style="width: 2rem; height: 2rem" stroke-width="4" />
        </div>

        <EmptyState v-else-if="invites.length === 0" icon="oi oi-users" :message="t('members.invites.empty')" />

        <div v-else class="flex flex-col divide-y divide-[var(--p-content-border-color)]">
          <div
            v-for="invite in invites"
            :key="invite.id"
            class="flex min-w-0 items-center gap-3 py-3 first:pt-0 last:pb-0"
          >
            <span class="min-w-0 flex-1 truncate text-sm text-[var(--p-text-color)]">{{ invite.email }}</span>
            <Tag :value="invite.role" severity="secondary" class="shrink-0" />
            <Button
              icon="oi oi-trash"
              text
              size="small"
              severity="danger"
              class="shrink-0"
              @click="(e: Event) => handleCancelInvite(e, invite)"
            />
          </div>
        </div>
      </template>
    </Card>

    <Dialog v-model:visible="showAddModal" modal :header="t('members.addModal.header')" class="w-full max-w-sm">
      <form class="flex flex-col gap-4" @submit.prevent="handleAdd">
        <Message v-if="addError" severity="error" :closable="false">{{ addError }}</Message>
        <div class="flex flex-col gap-2">
          <label for="add-email" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('members.addModal.email')
          }}</label>
          <InputText id="add-email" v-model="addEmail" type="email" placeholder="teammate@example.com" fluid />
        </div>
        <div class="flex flex-col gap-2">
          <label for="add-role" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('members.addModal.role')
          }}</label>
          <Select
            id="add-role"
            v-model="addRole"
            :options="roleOptions"
            option-label="label"
            option-value="value"
            fluid
          />
        </div>
        <p class="text-xs text-[var(--p-text-muted-color)]">{{ t('members.addModal.hint') }}</p>
        <Button type="submit" :label="t('members.addModal.submit')" :loading="adding" fluid />
      </form>
    </Dialog>
  </div>
</template>
