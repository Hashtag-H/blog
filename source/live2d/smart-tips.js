(function () {
  var started = false
  var lastText = ''
  var lastAt = 0

  function pick (items) {
    return items[Math.floor(Math.random() * items.length)]
  }

  function clean (text) {
    return (text || '').replace(/\s+/g, ' ').trim()
  }

  function showTip (text, duration) {
    var now = Date.now()
    if (!text || (text === lastText && now - lastAt < 8000)) return
    if (now - lastAt < 900) return

    lastText = text
    lastAt = now

    if (typeof window.showMessage === 'function') {
      window.showMessage(text, duration || 5600, 9)
      return
    }

    var tips = document.getElementById('waifu-tips')
    if (!tips) return
    tips.innerHTML = text
    tips.style.opacity = 1
    tips.style.display = 'block'
    window.clearTimeout(window.__waifuSmartTimer)
    window.__waifuSmartTimer = window.setTimeout(function () {
      tips.style.opacity = 0
    }, duration || 5600)
  }

  function articleCardFrom (target) {
    return target.closest('.recent-post-item, .aside-list-item, .relatedPosts-list a, .pagination-related, .article-sort-item')
  }

  function readArticleContext (target) {
    var card = articleCardFrom(target)
    var title = ''
    var category = ''
    var tags = []

    if (card) {
      var titleEl = card.querySelector('.article-title, .title, .article-sort-item-title, .info-item-2')
      title = clean((titleEl || card).textContent)
      var categoryEl = card.querySelector('.article-meta__categories, .post-meta-categories, .article-meta a')
      category = clean(categoryEl && categoryEl.textContent)
      tags = Array.from(card.querySelectorAll('.post-meta__tags, .article-meta__tags'))
        .map(function (item) { return clean(item.textContent).replace(/^#\s*/, '') })
        .filter(Boolean)
    }

    if (!title) {
      title = clean(document.querySelector('#post .post-title, #article-container h1, .post-title')?.textContent)
      category = clean(document.querySelector('.post-meta-categories, .article-meta__categories')?.textContent)
      tags = Array.from(document.querySelectorAll('.post-meta__tags, .article-meta__tags'))
        .map(function (item) { return clean(item.textContent).replace(/^#\s*/, '') })
        .filter(Boolean)
    }

    return { title: title, category: category, tags: tags }
  }

  function titlePrefix (title) {
    if (!title) return ''
    var shortTitle = title.length > 24 ? title.slice(0, 24) + '...' : title
    return '《' + shortTitle + '》：'
  }

  function topicMessage (context) {
    var haystack = [context.title, context.category].concat(context.tags).join(' ').toLowerCase()

    if (/rag|向量|检索|大模型|llm|embedding|资料库/.test(haystack)) {
      return pick([
        '这篇适合先看流程图：切分、召回、重排、生成，四步连起来就不乱了。',
        'RAG 的核心不是“让模型记住一切”，而是让它回答前先翻资料。',
        '读这类文章时，可以特别留意数据从文档到答案中间经过了几次筛选。'
      ])
    }

    if (/cnn|卷积|pytorch|transformer|attention|深度学习|神经网络|训练|模型|扩散|ai/.test(haystack)) {
      return pick([
        '深度学习文章建议抓三件事：输入是什么、模型怎么变换、损失怎么约束。',
        '这篇偏技术，先读标题和小节，再看细节会轻松很多。',
        '如果看到公式或结构图，不用急着背，先理解它解决了什么问题。'
      ])
    }

    if (/博客|写作|工作流|部署|工程|代码|编程|前端|后端|docker|fastapi|vue/.test(haystack)) {
      return pick([
        '工程类内容最好边看边记命令和坑点，之后真的会省很多时间。',
        '这类文章的价值通常藏在“为什么这样做”和“哪里容易错”里面。',
        '先看步骤，再回头看原因，工程实践会更容易落地。'
      ])
    }

    if (/名言|赏析|读书|生活|随笔|麦田|旅途|孔子|好奇心/.test(haystack)) {
      return pick([
        '这篇适合慢一点看，文字类内容不用急着马上得出结论。',
        '读赏析时可以问自己一句：它和我现在的生活有什么关系？',
        '这类文章像休息区，让脑子换一种节奏也挺重要。'
      ])
    }

    return pick([
      '这个标题挺有意思，点进去看看它真正想解决什么问题。',
      '如果时间不多，可以先看摘要、分类和标签，再决定要不要深读。',
      '这篇可能会给你一个新的切入点，我建议至少看完开头。'
    ])
  }

  function articleMessage (target) {
    var context = readArticleContext(target)
    return titlePrefix(context.title) + topicMessage(context)
  }

  function bind () {
    if (started) return
    started = true

    document.addEventListener('mouseover', function (event) {
      var target = event.target
      if (!(target instanceof Element)) return

      if (target.closest('.recent-post-item, .aside-list-item, .relatedPosts-list a, .pagination-related, .article-sort-item')) {
        showTip(articleMessage(target), 6200)
        return
      }

      if (target.closest('.toc-link')) {
        var toc = clean(target.textContent).replace(/^\d+\.\s*/, '')
        showTip('目录里这一节是“' + toc + '”。先看结构，再读正文，会更稳。', 4800)
        return
      }

      if (target.closest('.post-meta__tags, .article-meta__tags, .tag-cloud a')) {
        showTip('标签像线索，顺着它能找到同一主题下的更多文章。', 4600)
        return
      }

      if (target.closest('.article-meta__categories, .post-meta-categories, .card-category-list a')) {
        showTip('分类是小站的地图，从这里进去会比随便翻更快。', 4600)
        return
      }

      if (target.closest('#search-button, .search')) {
        showTip('想找内容可以直接搜关键词，比如 RAG、PyTorch、名言赏析。', 4800)
        return
      }
    }, true)

    document.addEventListener('click', function (event) {
      var target = event.target
      if (!(target instanceof Element)) return

      if (target.closest('#live2d, #waifu')) {
        showTip(pick([
          '我在呢。你点文章时，我会尽量按内容说点有用的话。',
          '今天适合读一篇，也适合把页面的小细节慢慢磨顺。',
          '别看我站在右下角，其实我一直在观察你正在看的内容。',
          '如果一篇文章太长，可以先看标题、摘要和标签，再决定要不要深读。',
          '我会少说废话，但关键位置会提醒你。'
        ]), 5800)
        return
      }

      if (target.closest('.article-title, .recent-post-item, .aside-list-item, .relatedPosts-list a, .pagination-related')) {
        showTip(articleMessage(target), 6200)
        return
      }

      if (target.closest('#menus .site-page')) {
        showTip('收到，准备切换页面。不同页面我也会换不同提示。', 4200)
      }
    }, true)

    document.addEventListener('copy', function () {
      showTip('复制好了。引用内容时记得保留出处，这样比较漂亮。', 4200)
    })

    document.addEventListener('visibilitychange', function () {
      if (!document.hidden) showTip('欢迎回来，刚刚这页我还替你守着。', 4200)
    })

    window.setTimeout(function () {
      showTip('我在右下角待命。点文章、标签或目录时，我会给你一点阅读建议。', 5800)
    }, 1800)
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bind, { once: true })
  } else {
    bind()
  }
})()
