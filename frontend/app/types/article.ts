export interface ArticleSummary {
  title: string
  slug: string
  summary: string
  category: string
  tags: string[]
  publishedAt: string
  readingMinutes: number
  cover?: string
  isTop?: boolean
}

export interface ArticleDetail extends ArticleSummary {
  contentMarkdown: string
  contentHtml?: string | null
}

export interface PageResponse<T> {
  records: T[]
  total: number
  page: number
  pageSize: number
}

export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}
