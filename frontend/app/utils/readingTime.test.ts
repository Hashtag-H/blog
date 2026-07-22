import { describe, expect, it } from 'vitest'
import { estimateReadingMinutes } from './readingTime'

describe('estimateReadingMinutes', () => {
  it('returns at least one minute', () => {
    expect(estimateReadingMinutes('')).toBe(1)
  })

  it('estimates mixed language content', () => {
    expect(estimateReadingMinutes('hello world '.repeat(500))).toBeGreaterThan(1)
  })
})

