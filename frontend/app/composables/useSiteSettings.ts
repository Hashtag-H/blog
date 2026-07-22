interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

export interface SiteSettings {
  siteTitle: string
  displayName: string
  motto: string
  avatarUrl: string
  backgroundUrl: string
  announcement: string
  githubUrl: string
  rssUrl: string
  live2dEnabled: boolean
  live2dCdnPath: string
  live2dModelId: number
  live2dTextureId: number
}

const defaultSiteSettings: SiteSettings = {
  siteTitle: '河南娃的小窝',
  displayName: '河南娃',
  motto: '愿麦浪祝颂你的旅途',
  avatarUrl: '/images/profile-id.webp',
  backgroundUrl: '/images/henan-wheatfield-bg.png',
  announcement: '欢迎来到河南娃的小窝！这里会记录编程、深度学习、读书和麦田里的灵光。',
  githubUrl: 'https://github.com/',
  rssUrl: '/rss.xml',
  live2dEnabled: true,
  live2dCdnPath: 'https://fastly.jsdelivr.net/gh/fghrsh/live2d_api@1.0.1/',
  live2dModelId: 0,
  live2dTextureId: 0
}

export const useSiteSettings = () => {
  const settings = useState<SiteSettings>('site-settings', () => ({ ...defaultSiteSettings }))
  const loaded = useState<boolean>('site-settings-loaded', () => false)
  const { apiFetch } = useApi()

  const applyBackground = () => {
    if (!import.meta.client || !settings.value.backgroundUrl) {
      return
    }
    document.documentElement.style.setProperty('--site-bg-image', `url("${settings.value.backgroundUrl}")`)
  }

  const loadSiteSettings = async () => {
    if (loaded.value) {
      applyBackground()
      return settings.value
    }

    try {
      const response = await apiFetch<ApiResponse<SiteSettings>>('/public/settings/site')
      settings.value = { ...defaultSiteSettings, ...response.data }
      loaded.value = true
      applyBackground()
    } catch {
      applyBackground()
    }
    return settings.value
  }

  return {
    settings,
    loadSiteSettings,
    applyBackground
  }
}
