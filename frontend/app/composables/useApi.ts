export const useApi = () => {
  const config = useRuntimeConfig()
  const serverBase = String(config.apiServerBase || config.public.apiBase)

  const apiFetch = $fetch.create({
    baseURL: import.meta.server ? serverBase : config.public.apiBase,
    credentials: 'include',
    onRequest({ options }) {
      if (import.meta.client) {
        const token = window.localStorage.getItem('admin_token')
        if (token) {
          const headers = new Headers(options.headers)
          headers.set('Authorization', `Bearer ${token}`)
          options.headers = headers
        }
      }
    }
  })

  return { apiFetch }
}
