INSERT INTO category (name, slug, description, sort)
VALUES
  ('Engineering', 'engineering', 'Notes about software engineering and architecture.', 10),
  ('AI Learning', 'ai-learning', 'Learning notes about AI systems and applied machine learning.', 20),
  ('Reading Notes', 'reading-notes', 'Book, paper, and article notes.', 30)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  sort = EXCLUDED.sort;

INSERT INTO tag (name, slug, description)
VALUES
  ('Spring Boot', 'spring-boot', 'Java backend development.'),
  ('Nuxt', 'nuxt', 'Vue and Nuxt frontend development.'),
  ('Recommendation', 'recommendation', 'Recommendation systems and ranking notes.'),
  ('Markdown', 'markdown', 'Writing and publishing workflow.')
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;

INSERT INTO series (name, slug, description, status, sort)
VALUES
  ('Recommendation Systems Basics', 'recommendation-systems-basics', 'A practical path for learning recommendation systems.', 'ACTIVE', 10)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  status = EXCLUDED.status,
  sort = EXCLUDED.sort;

-- Password hash placeholder is for documentation only. Replace it during stage 2 bootstrap.
-- Do not store plain text passwords.
INSERT INTO admin_user (username, password_hash, display_name, email)
VALUES
  ('admin', '$2a$10$replace.this.hash.in.stage2.bootstrap', 'Administrator', 'admin@example.com')
ON CONFLICT (username) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  email = EXCLUDED.email;
