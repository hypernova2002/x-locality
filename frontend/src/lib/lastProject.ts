const STORAGE_KEY = 'x-locality:lastProjectId'

export function rememberLastProject(id: string) {
  localStorage.setItem(STORAGE_KEY, id)
}

export function getLastProjectId(): string | null {
  return localStorage.getItem(STORAGE_KEY)
}
