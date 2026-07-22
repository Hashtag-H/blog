export const estimateReadingMinutes = (content: string): number => {
  const normalized = content.trim()

  if (!normalized) {
    return 1
  }

  const cjkCount = (normalized.match(/[\u4e00-\u9fff]/g) || []).length
  const wordCount = normalized
    .replace(/[\u4e00-\u9fff]/g, ' ')
    .split(/\s+/)
    .filter(Boolean).length

  return Math.max(1, Math.ceil((cjkCount + wordCount) / 400))
}

