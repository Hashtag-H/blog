INSERT INTO category (name, slug, description, sort)
VALUES
  ('深度学习', 'deep-learning', '神经网络、模型训练、生成式 AI 与工程实践笔记。', 20),
  ('博客', 'blog', '博客写作、站点维护与个人知识库搭建记录。', 30),
  ('名言赏析', 'quote-notes', '名人名言、句子摘录与学习反思。', 50)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  sort = EXCLUDED.sort,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO tag (name, slug, description)
VALUES
  ('深度学习', 'deep-learning', 'Deep learning notes.'),
  ('RAG', 'rag', 'Retrieval augmented generation notes.'),
  ('向量检索', 'vector-search', 'Embedding and vector retrieval practice.'),
  ('模型部署', 'model-deployment', 'Model serving and deployment practice.'),
  ('工程实践', 'engineering-practice', 'Engineering notes and production checklists.'),
  ('博客写作', 'blog-writing', 'Personal blog writing workflow.'),
  ('学习方法', 'learning-method', 'Learning methods and reflection.'),
  ('名言赏析', 'quote-notes', 'Quote appreciation and reflection.')
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO article (
  title, slug, summary, cover_url, content_markdown, content_html,
  category_id, status, is_top, allow_recommendation,
  seo_title, seo_description, word_count, reading_minutes, published_at
)
VALUES
(
  'RAG 入门笔记：把资料库接到大模型旁边',
  'rag-notes-from-documents-to-answer',
  '从文档切分、向量化、召回、重排到生成，梳理一个可落地的 RAG 系统为什么能让大模型回答得更贴近资料。',
  '/images/generated/rag-wheatfield-cover.png',
  $md$
## 为什么需要 RAG

大模型擅长语言组织和模式推理，但它不天然知道你的私有资料、项目文档和最新记录。RAG 的思路很朴素：先从资料库里找出相关片段，再把这些片段连同问题一起交给模型，让回答有据可依。

## 一个最小流程

一个可运行的 RAG 系统通常包含五步：

1. 文档清洗与切分。
2. 生成 embedding。
3. 写入向量数据库。
4. 根据问题召回相关片段。
5. 把片段整理进 prompt，再交给模型生成答案。

这里最容易被忽略的是切分。切得太碎，语义不完整；切得太长，召回结果噪声变多。实践里可以先按标题、段落和代码块边界切分，再根据内容长度做二次合并。

## 召回不是越多越好

很多系统一开始会把 topK 设得很大，结果模型收到太多片段，反而答得含糊。更稳的做法是先召回一批候选，再用重排模型或规则筛选，把真正有价值的上下文控制在可读范围内。

## 小结

RAG 的价值不是让模型“变全知”，而是给它一个可靠的资料入口。把检索、排序和引用链路做好，回答质量会比单纯加长提示词稳定得多。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'deep-learning'),
  'PUBLISHED',
  TRUE,
  TRUE,
  'RAG 入门笔记：把资料库接到大模型旁边',
  'RAG、文档切分、向量检索、召回重排与生成流程入门笔记。',
  780,
  4,
  TIMESTAMPTZ '2026-07-22 09:20:00+08'
),
(
  '从训练到上线：深度学习模型部署清单',
  'deep-learning-model-deployment-checklist',
  '整理模型从实验室走到线上服务前需要检查的格式导出、推理性能、监控、回滚和版本管理问题。',
  '/images/generated/model-deployment-wheatfield-cover.png',
  $md$
## 部署不是训练的最后一步

很多模型在 notebook 里表现不错，一到线上就暴露问题：输入格式不稳定、推理延迟过高、依赖版本漂移、日志不够完整。部署应该从训练阶段就开始考虑，而不是等模型训练完才补。

## 上线前的五个检查点

- 输入输出 schema 是否固定。
- 模型文件、预处理逻辑和后处理逻辑是否一同版本化。
- 推理延迟是否满足业务要求。
- 异常样本是否能被记录和回放。
- 新版本是否可以灰度和回滚。

## 性能优化先看瓶颈

如果接口慢，不要急着换更复杂的推理框架。先记录模型耗时、预处理耗时、网络耗时和队列等待时间。很多时候真正拖慢系统的不是模型本身，而是图片解码、批处理策略或远程存储读取。

## 小结

模型部署的核心是可重复、可观察、可回退。把这些基础设施补齐之后，模型迭代才不会变成一次次冒险。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'deep-learning'),
  'PUBLISHED',
  FALSE,
  TRUE,
  '从训练到上线：深度学习模型部署清单',
  '深度学习模型部署、推理性能、版本管理、监控和回滚清单。',
  760,
  4,
  TIMESTAMPTZ '2026-07-21 20:30:00+08'
),
(
  '把博客写顺手：从草稿箱到发布的工作流',
  'personal-blog-writing-workflow',
  '记录一套适合个人博客长期维护的写作流程：选题、草稿、素材、封面、校对、分类和发布复盘。',
  '/images/generated/blog-workflow-wheatfield-cover.png',
  $md$
## 写博客先降低启动成本

很多文章没有写完，不是因为想法不好，而是启动成本太高。我的做法是把文章拆成几个轻量阶段：先记标题，再补提纲，然后慢慢填例子。只要草稿箱里有半成品，写作就不会每次都从零开始。

## 一个简单流程

1. 用一句话写清楚文章要解决什么问题。
2. 列出三到五个小标题。
3. 给每个小标题补一个例子或经历。
4. 写完后删掉重复表达。
5. 最后再补分类、标签和封面。

## 分类和标签要克制

分类像书架，标签像便签。分类太多会让读者找不到方向，标签太少又不利于串联文章。个人博客可以先保持少量稳定分类，再用标签描述更细的主题。

## 小结

顺手的博客系统不是功能越多越好，而是让你愿意持续写。写作流程越稳定，灵感越容易落到页面上。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'blog'),
  'PUBLISHED',
  TRUE,
  TRUE,
  '把博客写顺手：从草稿箱到发布的工作流',
  '个人博客写作流程、草稿管理、分类标签和发布复盘。',
  720,
  4,
  TIMESTAMPTZ '2026-07-20 18:40:00+08'
),
(
  '名言赏析：行稳致远，也要日日更新',
  'quote-steady-learning-daily-renewal',
  '借“行稳致远”的意思谈学习节奏：慢不是停下，稳也不是保守，关键是让每天都有一点真实推进。',
  '/images/generated/steady-learning-wheatfield-cover.png',
  $md$
## 先把节奏放稳

学习最怕一开始冲得太猛，几天之后完全停摆。行稳致远不是慢吞吞，而是找到一种可以长期持续的速度。今天读一页、写一段、跑一个小实验，看起来不惊人，但会在几个月后形成厚度。

## 稳和新并不冲突

稳定不是重复旧动作。真正有效的稳定，是每天都留下一个小小的更新：修正一个概念、补全一个例子、复盘一次失败、讲清楚一个问题。这样积累下来的知识才会有生命力。

## 给自己的三个提醒

- 不用把计划写得太满，留一点余地给生活。
- 不用每天都追热点，先把手边的问题弄明白。
- 不用害怕慢，只要方向没有丢，慢也是前进。

## 小结

行稳致远的重点不在“慢”，而在“不断”。能把小进步稳稳接起来，就是一种很强的长期能力。
$md$,
  NULL,
  (SELECT id FROM category WHERE slug = 'quote-notes'),
  'PUBLISHED',
  FALSE,
  TRUE,
  '名言赏析：行稳致远，也要日日更新',
  '学习方法、长期主义、行稳致远和每日复盘的短文赏析。',
  680,
  3,
  TIMESTAMPTZ '2026-07-19 21:00:00+08'
)
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title,
  summary = EXCLUDED.summary,
  cover_url = EXCLUDED.cover_url,
  content_markdown = EXCLUDED.content_markdown,
  content_html = EXCLUDED.content_html,
  category_id = EXCLUDED.category_id,
  status = EXCLUDED.status,
  is_top = EXCLUDED.is_top,
  allow_recommendation = EXCLUDED.allow_recommendation,
  seo_title = EXCLUDED.seo_title,
  seo_description = EXCLUDED.seo_description,
  word_count = EXCLUDED.word_count,
  reading_minutes = EXCLUDED.reading_minutes,
  published_at = EXCLUDED.published_at,
  updated_at = CURRENT_TIMESTAMP,
  deleted = FALSE;

DELETE FROM article_tag
WHERE article_id IN (
  SELECT id FROM article
  WHERE slug IN (
    'rag-notes-from-documents-to-answer',
    'deep-learning-model-deployment-checklist',
    'personal-blog-writing-workflow',
    'quote-steady-learning-daily-renewal'
  )
);

INSERT INTO article_tag (article_id, tag_id)
SELECT a.id, t.id
FROM (
  VALUES
    ('rag-notes-from-documents-to-answer', 'rag'),
    ('rag-notes-from-documents-to-answer', 'vector-search'),
    ('rag-notes-from-documents-to-answer', 'deep-learning'),
    ('deep-learning-model-deployment-checklist', 'model-deployment'),
    ('deep-learning-model-deployment-checklist', 'engineering-practice'),
    ('deep-learning-model-deployment-checklist', 'deep-learning'),
    ('personal-blog-writing-workflow', 'blog-writing'),
    ('personal-blog-writing-workflow', 'engineering-practice'),
    ('personal-blog-writing-workflow', 'learning-method'),
    ('quote-steady-learning-daily-renewal', 'quote-notes'),
    ('quote-steady-learning-daily-renewal', 'learning-method')
) AS pairs(article_slug, tag_slug)
JOIN article a ON a.slug = pairs.article_slug
JOIN tag t ON t.slug = pairs.tag_slug
ON CONFLICT DO NOTHING;
