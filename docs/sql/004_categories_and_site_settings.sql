INSERT INTO category (name, slug, description, sort)
VALUES
  ('编程', 'programming', '工程开发、代码实践与环境配置', 10),
  ('深度学习', 'deep-learning', '神经网络、模型训练与 AI 研究笔记', 20),
  ('博客', 'blog', '博客写作与站点记录', 30),
  ('读书札记', 'reading-notes', '阅读记录与知识整理', 40),
  ('名言赏析', 'quote-notes', '名人名言、句子摘录与短评', 50),
  ('生活', 'life', '日常记录、校园生活与随笔', 60)
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    sort = EXCLUDED.sort,
    updated_at = CURRENT_TIMESTAMP;

CREATE TABLE IF NOT EXISTS site_setting (
  key VARCHAR(100) PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO site_setting (key, value)
VALUES
  ('siteTitle', '河南娃的小窝'),
  ('displayName', '河南娃'),
  ('motto', '愿麦浪祝颂你的旅途'),
  ('avatarUrl', '/images/profile-id.webp'),
  ('backgroundUrl', '/images/henan-wheatfield-bg.png'),
  ('announcement', '欢迎来到河南娃的小窝！这里会记录编程、深度学习、读书和麦田里的灵光。'),
  ('githubUrl', 'https://github.com/'),
  ('rssUrl', '/rss.xml')
ON CONFLICT (key) DO NOTHING;
