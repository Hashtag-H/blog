export type AdminToastType = 'success' | 'error' | 'info'

export interface AdminToast {
  id: number
  type: AdminToastType
  title: string
  message?: string
}

let toastId = 0

export const useAdminToast = () => {
  const toasts = useState<AdminToast[]>('admin-toasts', () => [])

  const dismissToast = (id: number) => {
    toasts.value = toasts.value.filter(toast => toast.id !== id)
  }

  const showToast = (
    payload: string | Omit<AdminToast, 'id'>,
    type: AdminToastType = 'info',
    duration = 3600
  ) => {
    const toast: AdminToast = typeof payload === 'string'
      ? { id: ++toastId, type, title: payload }
      : { id: ++toastId, ...payload }

    toasts.value = [...toasts.value, toast]

    if (import.meta.client && duration > 0) {
      window.setTimeout(() => dismissToast(toast.id), duration)
    }

    return toast.id
  }

  return {
    toasts,
    showToast,
    dismissToast
  }
}
