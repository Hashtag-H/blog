import { fairyDustCursor } from 'cursor-effects'

export default defineNuxtPlugin(() => {
  let effect: { destroy: () => void } | null = null

  const enableCursorEffect = () => {
    if (effect || window.matchMedia('(max-width: 767px)').matches) {
      return
    }

    effect = fairyDustCursor({
      colors: ['#d99a2b', '#49b1f5', '#f6d48d', '#94f0d3']
    })
  }

  const disableCursorEffect = () => {
    effect?.destroy()
    effect = null
  }

  const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
  const widthQuery = window.matchMedia('(max-width: 767px)')
  const syncCursorEffect = () => {
    if (motionQuery.matches || widthQuery.matches) {
      disableCursorEffect()
      return
    }

    enableCursorEffect()
  }

  window.addEventListener('load', syncCursorEffect, { once: true })
  motionQuery.addEventListener('change', syncCursorEffect)
  widthQuery.addEventListener('change', syncCursorEffect)
})
