(function () {
  var subtitle = '愿麦浪祝颂你的旅途'

  function loopSubtitle () {
    var el = document.querySelector('#site-subtitle')
    if (!el) return
    var i = 0
    var deleting = false

    setInterval(function () {
      if (deleting) {
        i -= 1
        if (i <= 0) deleting = false
      } else {
        i += 1
        if (i >= subtitle.length + 8) deleting = true
      }

      el.textContent = subtitle.slice(0, Math.min(i, subtitle.length))
    }, 160)
  }

  function loadScript (src, done) {
    var script = document.createElement('script')
    script.src = src
    script.defer = true
    script.onload = done || null
    document.body.appendChild(script)
  }

  function mountLive2d () {
    if (window.innerWidth < 768 || document.getElementById('waifu')) return
    window.live2d_path = '/live2d/'
    loadScript('/live2d/live2d.js')
  }

  function mountCursorEffects () {
    if (window.innerWidth < 768 || window.__henanCursorEffectsMounted) return
    window.__henanCursorEffectsMounted = true
    loadScript('https://cdn.jsdelivr.net/npm/cursor-effects@1.0.18/dist/browser.js', function () {
      if (!window.cursoreffects || !window.cursoreffects.fairyDustCursor) return
      window.__henanCursorEffect = new window.cursoreffects.fairyDustCursor({
        colors: ['#d99a2b', '#f5d37a', '#ffffff'],
        fairySymbol: '✦'
      })
    })
  }

  function markActiveMenu () {
    var path = window.location.pathname.replace(/\/index\.html$/, '/')
    document.querySelectorAll('#menus .menus_item').forEach(function (item) {
      item.classList.remove('is-current')
      item.querySelectorAll('a.site-page').forEach(function (link) {
        var href = new URL(link.getAttribute('href'), window.location.origin).pathname
        if (href === path || (href !== '/' && path.indexOf(href) === 0)) {
          item.classList.add('is-current')
        }
      })
    })
  }

  function bindMenuDropdowns () {
    document.querySelectorAll('#menus .menus_item').forEach(function (item) {
      var trigger = item.querySelector(':scope > .site-page.group')
      var panel = item.querySelector(':scope > .menus_item_child')
      if (!trigger || !panel || item.dataset.dropdownBound) return

      item.dataset.dropdownBound = 'true'
      trigger.setAttribute('role', 'button')
      trigger.setAttribute('tabindex', '0')

      function togglePanel (event) {
        event.preventDefault()
        event.stopPropagation()
        document.querySelectorAll('#menus .menus_item.is-open').forEach(function (openItem) {
          if (openItem !== item) openItem.classList.remove('is-open')
        })
        item.classList.toggle('is-open')
      }

      trigger.addEventListener('click', togglePanel)
      trigger.addEventListener('keydown', function (event) {
        if (event.key === 'Enter' || event.key === ' ') togglePanel(event)
      })
    })

    document.addEventListener('click', function () {
      document.querySelectorAll('#menus .menus_item.is-open').forEach(function (item) {
        item.classList.remove('is-open')
      })
    })
  }

  function mountThemeToggle () {
    var nav = document.getElementById('nav')
    if (!nav || nav.querySelector('.nav-theme-toggle')) return

    var button = document.createElement('button')
    button.type = 'button'
    button.className = 'nav-theme-toggle'

    function syncText () {
      var isDark = document.documentElement.getAttribute('data-theme') === 'dark'
      button.innerHTML = '<i class="fas fa-moon"></i><span>' + (isDark ? '浅色' : '深色') + '</span>'
    }

    button.addEventListener('click', function () {
      var butterflyDarkMode = document.getElementById('darkmode')
      if (butterflyDarkMode) {
        butterflyDarkMode.click()
      } else {
        var current = document.documentElement.getAttribute('data-theme')
        document.documentElement.setAttribute('data-theme', current === 'dark' ? 'light' : 'dark')
      }
      window.setTimeout(syncText, 80)
    })

    nav.appendChild(button)
    syncText()
  }

  function bindFloatingNav () {
    var nav = document.getElementById('nav')
    if (!nav) return

    var lastY = window.scrollY || 0
    var ticking = false

    function showNav () {
      nav.classList.remove('nav-hidden')
    }

    function hideNav () {
      if ((window.scrollY || 0) > 120) nav.classList.add('nav-hidden')
    }

    function updateNav () {
      var currentY = window.scrollY || 0
      var delta = currentY - lastY

      if (delta > 8) {
        hideNav()
      } else if (delta < -8 || currentY < 80) {
        showNav()
      }

      lastY = currentY
      ticking = false
    }

    window.addEventListener('scroll', function () {
      if (ticking) return
      ticking = true
      window.requestAnimationFrame(updateNav)
    }, { passive: true })

    window.addEventListener('mousemove', function (event) {
      if (event.clientY < 86) showNav()
    }, { passive: true })

    nav.addEventListener('mouseenter', showNav)
  }

  function boot () {
    loopSubtitle()
    mountLive2d()
    mountCursorEffects()
    markActiveMenu()
    bindMenuDropdowns()
    mountThemeToggle()
    bindFloatingNav()
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot)
  } else {
    boot()
  }
})()
