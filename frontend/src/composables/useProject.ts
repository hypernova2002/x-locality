import { inject, type InjectionKey, type Ref } from 'vue'
import type { Project } from '@/api/types'

export const PROJECT_KEY: InjectionKey<Ref<Project | null>> = Symbol('project')
export const PROJECTS_KEY: InjectionKey<Ref<Project[]>> = Symbol('projects')
export const PROJECTS_LOADING_KEY: InjectionKey<Ref<boolean>> = Symbol('projectsLoading')
export const RELOAD_PROJECTS_KEY: InjectionKey<() => Promise<void>> = Symbol('reloadProjects')

// AppShell fetches the project list once and provides it (plus the current
// project, derived from the route) to every descendant - nested views never
// fetch project data themselves.
export function useProject() {
  const project = inject(PROJECT_KEY)
  const reloadProject = inject(RELOAD_PROJECTS_KEY)

  if (!project || !reloadProject) {
    throw new Error('useProject() must be called within AppShell')
  }

  return { project, reloadProject }
}

export function useProjects() {
  const projects = inject(PROJECTS_KEY)
  const projectsLoading = inject(PROJECTS_LOADING_KEY)
  const reloadProjects = inject(RELOAD_PROJECTS_KEY)

  if (!projects || !projectsLoading || !reloadProjects) {
    throw new Error('useProjects() must be called within AppShell')
  }

  return { projects, projectsLoading, reloadProjects }
}
