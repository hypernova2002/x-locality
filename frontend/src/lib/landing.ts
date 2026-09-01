import * as projectsApi from '@/api/projects'
import { getLastProjectId } from './lastProject'

// Where to send the user when they open the app: their last-active project's
// translations page, falling back to the first project, or the projects list
// if they don't have one yet.
export async function resolveLandingRoute(token: string) {
  const { data: projects } = await projectsApi.listProjects(token)
  if (projects.length === 0) return { name: 'projects' as const }

  const lastId = getLastProjectId()
  const target = projects.find((p) => p.id === lastId) ?? projects[0]!
  return { name: 'project-translations' as const, params: { projectId: target.id } }
}
