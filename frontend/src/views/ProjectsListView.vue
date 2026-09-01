<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Button from 'openvue/button'
import Dialog from 'openvue/dialog'
import EmptyState from '@/components/EmptyState.vue'
import InputText from 'openvue/inputtext'
import Message from 'openvue/message'
import ProgressSpinner from 'openvue/progressspinner'
import { useToast } from 'openvue/usetoast'
import { useAuthStore } from '@/stores/auth'
import { useProjects } from '@/composables/useProject'
import * as projectsApi from '@/api/projects'
import { ApiError } from '@/api/client'
import type { Project } from '@/api/types'

const auth = useAuthStore()
const router = useRouter()
const toast = useToast()
const { t } = useI18n()
const { projects, projectsLoading, reloadProjects } = useProjects()

const showCreateModal = ref(false)
const newProjectName = ref('')
const createError = ref<string | null>(null)
const creating = ref(false)

async function handleCreate() {
  createError.value = null
  creating.value = true
  try {
    const { data } = await projectsApi.createProject(auth.token!, { name: newProjectName.value })
    showCreateModal.value = false
    newProjectName.value = ''
    toast.add({ severity: 'success', summary: t('projects.createdToast'), life: 3000 })
    await reloadProjects()
    router.push(`/projects/${data.id}/translations`)
  } catch (e) {
    createError.value = e instanceof ApiError ? e.detail || e.title : t('common.somethingWentWrong')
  } finally {
    creating.value = false
  }
}

function openProject(project: Project) {
  router.push(`/projects/${project.id}/translations`)
}
</script>

<template>
  <div>
    <div class="mb-4 flex items-center justify-end">
      <Button :label="t('projects.newProject')" icon="oi oi-plus" @click="showCreateModal = true" />
    </div>

    <div v-if="projectsLoading" class="flex justify-center py-12">
      <ProgressSpinner style="width: 2.5rem; height: 2.5rem" stroke-width="4" />
    </div>

    <EmptyState
      v-else-if="projects.length === 0"
      icon="oi oi-folder"
      :message="t('projects.empty')"
      :action-label="t('projects.newProject')"
      @action="showCreateModal = true"
    />

    <div v-else class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <button
        v-for="project in projects"
        :key="project.id"
        type="button"
        class="flex flex-col gap-3 rounded-lg border border-[var(--p-content-border-color)] bg-[var(--p-content-background)] p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-[var(--p-primary-color)] hover:shadow-md"
        @click="openProject(project)"
      >
        <div>
          <h2 class="font-medium text-[var(--p-text-color)]">{{ project.name }}</h2>
          <p class="text-sm text-[var(--p-text-muted-color)]">{{ project.slug }}</p>
        </div>
      </button>
    </div>

    <Dialog
      v-model:visible="showCreateModal"
      modal
      :header="t('projects.createModal.header')"
      class="w-full max-w-sm"
    >
      <form class="flex flex-col gap-4" @submit.prevent="handleCreate">
        <Message v-if="createError" severity="error" :closable="false">{{ createError }}</Message>
        <div class="flex flex-col gap-2">
          <label for="project-name" class="text-sm font-medium text-[var(--p-text-color)]">{{
            t('projects.createModal.name')
          }}</label>
          <InputText
            id="project-name"
            v-model="newProjectName"
            :placeholder="t('projects.createModal.namePlaceholder')"
            fluid
          />
        </div>
        <Button type="submit" :label="t('projects.createModal.submit')" :loading="creating" fluid />
      </form>
    </Dialog>
  </div>
</template>
