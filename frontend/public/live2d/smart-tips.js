(function () {
  var smartTipsStarted = false;
  var lastMessage = '';

  function pick(list) {
    return list[Math.floor(Math.random() * list.length)];
  }

  function cleanText(value) {
    return (value || '').replace(/\s+/g, ' ').trim();
  }

  function getTipsEl() {
    return document.getElementById('waifu-tips');
  }

  function showSmartTip(text, duration) {
    if (!text || text === lastMessage) {
      return;
    }

    lastMessage = text;

    if (typeof window.showMessage === 'function') {
      window.showMessage(text, duration || 5200, 9);
      return;
    }

    var tips = getTipsEl();
    if (!tips) {
      return;
    }

    tips.innerHTML = text;
    tips.style.opacity = 1;
    tips.style.display = 'block';
    window.clearTimeout(window.__live2dSmartTipTimer);
    window.__live2dSmartTipTimer = window.setTimeout(function () {
      tips.style.opacity = 0;
    }, duration || 5200);
  }

  function getArticleContext(target) {
    var card = target.closest('.post-card, .article-admin-card, .search-result-card, .archive-feature, .archive-row, .taxonomy-posts a');
    var title = '';
    var category = '';
    var tags = [];

    if (card) {
      title = cleanText(
        (card.querySelector('.post-card-title, .article-admin-title, strong') || card).textContent
      );
      category = cleanText(
        (card.querySelector('.post-card-category, .article-category-badge, .article-admin-topline span:nth-child(3)') || {}).textContent
      );
      tags = Array.from(card.querySelectorAll('.post-card-tags span, .article-tag-row span'))
        .map(function (item) { return cleanText(item.textContent).replace(/^#\s*/, ''); })
        .filter(Boolean);
    }

    if (!title) {
      title = cleanText(document.querySelector('.article-hero-card h1, .article-header-block h1, .public-hero h1')?.textContent);
      tags = Array.from(document.querySelectorAll('.article-tag-row span'))
        .map(function (item) { return cleanText(item.textContent).replace(/^#\s*/, ''); })
        .filter(Boolean);
    }

    return { title: title, category: category, tags: tags };
  }

  function topicLine(context) {
    var haystack = [context.title, context.category].concat(context.tags).join(' ').toLowerCase();
    if (/cnn|卷积|pytorch|深度学习|transformer|attention|神经网络|模型|ai|机器学习/.test(haystack)) {
      return pick([
        '这篇偏 AI/深度学习，建议留意它的问题定义、模型结构和实验结论。',
        '看到深度学习相关内容啦。先抓住输入、特征、损失函数这三条线，读起来会顺很多。',
        '这类技术文可以边看边记关键词：数据、模型、训练、评估。'
      ]);
    }
    if (/spring|nuxt|java|vue|fastapi|代码|编程|工程|架构|docker|后端|前端/.test(haystack)) {
      return pick([
        '这篇偏工程实践，重点可以看实现步骤、踩坑位置和可复用的配置。',
        '编程文章最怕只看热闹，建议顺手跑一下示例或者记一条命令。',
        '这是工程向内容。先看目录，再看关键代码，会省很多力气。'
      ]);
    }
    if (/名言|阅读|赏析|生活|随笔|麦田|小窝|旅途/.test(haystack)) {
      return pick([
        '这篇更像生活和阅读札记，适合慢慢看，不用急着得出结论。',
        '文字类内容可以先感受语气，再回头看它真正想表达的意思。',
        '这里不是刷题时间，是让脑子透透气的时间。'
      ]);
    }
    return pick([
      '这篇标题挺有意思，点进去看看它的重点在哪里。',
      '如果时间不多，可以先看摘要和标签，再决定要不要深读。',
      '这篇可能会给你一个新的切入点。'
    ]);
  }

  function articleMessage(target) {
    var context = getArticleContext(target);
    var prefix = context.title ? '《' + context.title.slice(0, 28) + (context.title.length > 28 ? '...' : '') + '》：' : '';
    return prefix + topicLine(context);
  }

  function bindSmartTips() {
    if (smartTipsStarted) {
      return;
    }
    smartTipsStarted = true;

    document.addEventListener('mouseover', function (event) {
      var target = event.target;
      if (!(target instanceof Element)) {
        return;
      }

      if (target.closest('.post-card, .archive-row, .search-result-card, .taxonomy-posts a, .article-admin-card')) {
        showSmartTip(articleMessage(target), 5600);
        return;
      }

      if (target.closest('.article-content h2, .article-content h3')) {
        var heading = cleanText(target.textContent);
        showSmartTip('这一节是“' + heading + '”。读完标题再看正文，会更容易抓住结构。', 4800);
        return;
      }

      if (target.closest('.public-search-input')) {
        showSmartTip('可以输入“深度学习”“编程”“名言”这类关键词，我会陪你一起筛文章。', 4800);
      }
    }, true);

    document.addEventListener('click', function (event) {
      var target = event.target;
      if (!(target instanceof Element)) {
        return;
      }

      if (target.closest('#live2d')) {
        showSmartTip(pick([
          '我在。你可以把我当成页面右下角的小助手。',
          '收到点击。要不要先从置顶文章读起？',
          '我会按你正在看的内容说话，不只是随机冒泡。',
          '今天适合把一篇文章读完，也适合把一个小功能打磨好。',
          '如果页面哪里不顺眼，告诉我，我们继续调。'
        ]), 5600);
        return;
      }

      if (target.closest('.post-card, .archive-row, .search-result-card, .taxonomy-posts a')) {
        showSmartTip(articleMessage(target), 5200);
      }
    }, true);

    var path = location.pathname;
    window.setInterval(function () {
      if (location.pathname === path) {
        return;
      }
      path = location.pathname;
      window.setTimeout(function () {
        if (/^\/articles\//.test(path)) {
          showSmartTip(articleMessage(document.body), 5800);
        } else if (/^\/admin/.test(path)) {
          showSmartTip('进入后台管理区。关键操作完成后，我会在右上角给你反馈。', 5200);
        }
      }, 700);
    }, 900);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bindSmartTips, { once: true });
  } else {
    bindSmartTips();
  }
})();
