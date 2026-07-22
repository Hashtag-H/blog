CREATE TABLE IF NOT EXISTS admin_user (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(64) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  email VARCHAR(180),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT uk_admin_user_username UNIQUE (username)
);

CREATE TABLE IF NOT EXISTS category (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  slug VARCHAR(120) NOT NULL,
  description VARCHAR(500),
  sort INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_category_slug UNIQUE (slug)
);

CREATE INDEX IF NOT EXISTS idx_category_slug ON category (slug);

CREATE TABLE IF NOT EXISTS tag (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  slug VARCHAR(120) NOT NULL,
  description VARCHAR(500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_tag_slug UNIQUE (slug)
);

CREATE INDEX IF NOT EXISTS idx_tag_slug ON tag (slug);

CREATE TABLE IF NOT EXISTS series (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  slug VARCHAR(160) NOT NULL,
  description VARCHAR(800),
  cover_url VARCHAR(500),
  status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
  sort INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_series_slug UNIQUE (slug)
);

CREATE INDEX IF NOT EXISTS idx_series_slug ON series (slug);

CREATE TABLE IF NOT EXISTS article (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(220) NOT NULL,
  slug VARCHAR(240) NOT NULL,
  summary VARCHAR(1000),
  cover_url VARCHAR(500),
  content_markdown TEXT NOT NULL,
  content_html TEXT,
  category_id BIGINT,
  series_id BIGINT,
  series_order INTEGER,
  status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
  is_top BOOLEAN NOT NULL DEFAULT FALSE,
  allow_recommendation BOOLEAN NOT NULL DEFAULT TRUE,
  seo_title VARCHAR(220),
  seo_description VARCHAR(500),
  word_count INTEGER NOT NULL DEFAULT 0,
  reading_minutes INTEGER NOT NULL DEFAULT 1,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT uk_article_slug UNIQUE (slug),
  CONSTRAINT fk_article_category FOREIGN KEY (category_id) REFERENCES category(id),
  CONSTRAINT fk_article_series FOREIGN KEY (series_id) REFERENCES series(id)
);

CREATE INDEX IF NOT EXISTS idx_article_slug ON article (slug);
CREATE INDEX IF NOT EXISTS idx_article_status ON article (status);
CREATE INDEX IF NOT EXISTS idx_article_category_id ON article (category_id);
CREATE INDEX IF NOT EXISTS idx_article_published_at ON article (published_at);
CREATE INDEX IF NOT EXISTS idx_article_series_id ON article (series_id);

CREATE TABLE IF NOT EXISTS article_tag (
  article_id BIGINT NOT NULL,
  tag_id BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (article_id, tag_id),
  CONSTRAINT fk_article_tag_article FOREIGN KEY (article_id) REFERENCES article(id),
  CONSTRAINT fk_article_tag_tag FOREIGN KEY (tag_id) REFERENCES tag(id)
);

CREATE INDEX IF NOT EXISTS idx_article_tag_tag_id ON article_tag (tag_id);

CREATE TABLE IF NOT EXISTS site_setting (
  key VARCHAR(100) PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS external_recommendation (
  id BIGSERIAL PRIMARY KEY,
  article_id BIGINT NOT NULL,
  title VARCHAR(300) NOT NULL,
  url VARCHAR(1000) NOT NULL,
  source VARCHAR(120),
  domain VARCHAR(180),
  summary VARCHAR(1200),
  recommendation_reason VARCHAR(800),
  matched_keywords VARCHAR(500),
  score NUMERIC(8,2) NOT NULL DEFAULT 0,
  status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
  external_published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_external_recommendation_url_article UNIQUE (article_id, url),
  CONSTRAINT fk_external_recommendation_article FOREIGN KEY (article_id) REFERENCES article(id)
);

CREATE INDEX IF NOT EXISTS idx_external_recommendation_article_id ON external_recommendation (article_id);
CREATE INDEX IF NOT EXISTS idx_external_recommendation_status ON external_recommendation (status);
CREATE INDEX IF NOT EXISTS idx_external_recommendation_score ON external_recommendation (score);
