// Default for local dev - the app falls back to VITE_API_BASE_URL when
// apiBaseUrl is unset. The published production image overwrites this file
// at container startup from the API_BASE_URL env var (see
// docker/frontend/docker-entrypoint.sh) - the built JS bundle never has an
// API URL baked into it.
window.__APP_CONFIG__ = {}
