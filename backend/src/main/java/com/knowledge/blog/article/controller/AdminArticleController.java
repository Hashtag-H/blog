package com.knowledge.blog.article.controller;

import com.knowledge.blog.article.dto.AdminArticleRequest;
import com.knowledge.blog.article.vo.AdminArticleVO;
import com.knowledge.blog.common.api.ApiResponse;
import com.knowledge.blog.common.api.PageResponse;
import jakarta.validation.Valid;
import java.sql.Timestamp;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/articles")
public class AdminArticleController {

    private static final Pattern WORD_PATTERN = Pattern.compile("[\\p{L}\\p{N}]+");
    private static final RowMapper<AdminArticleVO> ARTICLE_MAPPER = (rs, rowNum) -> new AdminArticleVO(
        rs.getLong("id"),
        rs.getString("title"),
        rs.getString("slug"),
        rs.getString("summary"),
        rs.getString("cover_url"),
        nullableLong(rs.getObject("category_id")),
        rs.getString("category_name"),
        rs.getString("content_markdown"),
        rs.getString("status"),
        rs.getInt("word_count"),
        rs.getInt("reading_minutes"),
        toOffsetDateTime(rs.getTimestamp("published_at")),
        toOffsetDateTime(rs.getTimestamp("created_at")),
        toOffsetDateTime(rs.getTimestamp("updated_at")),
        rs.getBoolean("is_top"),
        List.of()
    );

    private final JdbcTemplate jdbcTemplate;

    public AdminArticleController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public ApiResponse<PageResponse<AdminArticleVO>> listArticles() {
        ensureTopColumn();
        List<AdminArticleVO> articles = jdbcTemplate.query("""
            SELECT a.id, a.title, a.slug, a.summary, a.cover_url, a.category_id,
                   COALESCE(c.name, '未分类') AS category_name,
                   a.content_markdown, a.status, a.word_count, a.reading_minutes,
                   a.published_at, a.created_at, a.updated_at, a.is_top
            FROM article a
            LEFT JOIN category c ON c.id = a.category_id
            WHERE a.deleted = FALSE
            ORDER BY a.is_top DESC, a.updated_at DESC
            LIMIT 100
            """, ARTICLE_MAPPER);

        return ApiResponse.success(new PageResponse<>(articles, articles.size(), 1, 100));
    }

    @GetMapping("/{id}")
    public ApiResponse<AdminArticleVO> getArticle(@PathVariable Long id) {
        ensureTopColumn();
        AdminArticleVO article = findArticle(id);
        return ApiResponse.success(withTags(article));
    }

    @PostMapping
    @Transactional
    public ApiResponse<AdminArticleVO> createArticle(@Valid @RequestBody AdminArticleRequest request) {
        ensureTopColumn();
        ArticleStats stats = calculateStats(request.contentMarkdown());
        String slug = normalizeSlug(request.slug(), request.title());
        String status = normalizeStatus(request.status());
        Long categoryId = resolveCategoryId(request);
        Timestamp publishedAt = "PUBLISHED".equals(status) ? Timestamp.from(OffsetDateTime.now().toInstant()) : null;

        Long id = jdbcTemplate.queryForObject("""
            INSERT INTO article (
              title, slug, summary, cover_url, category_id, content_markdown, status,
              word_count, reading_minutes, published_at, is_top
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            RETURNING id
            """,
            Long.class,
            request.title().trim(),
            slug,
            blankToNull(request.summary()),
            blankToNull(request.coverUrl()),
            categoryId,
            request.contentMarkdown(),
            status,
            stats.wordCount(),
            stats.readingMinutes(),
            publishedAt,
            Boolean.TRUE.equals(request.isTop())
        );

        syncTags(id, request.tags());
        return ApiResponse.success(withTags(findArticle(id)));
    }

    @PutMapping("/{id}")
    @Transactional
    public ApiResponse<AdminArticleVO> updateArticle(
        @PathVariable Long id,
        @Valid @RequestBody AdminArticleRequest request
    ) {
        ensureTopColumn();
        ArticleStats stats = calculateStats(request.contentMarkdown());
        String status = normalizeStatus(request.status());
        String slug = normalizeSlug(request.slug(), request.title());
        Long categoryId = resolveCategoryId(request);
        Timestamp publishedAt = publishedAtForUpdate(id, status);

        int updated = jdbcTemplate.update("""
            UPDATE article
            SET title = ?,
                slug = ?,
                summary = ?,
                cover_url = ?,
                category_id = ?,
                content_markdown = ?,
                status = ?,
                word_count = ?,
                reading_minutes = ?,
                published_at = ?,
                is_top = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ? AND deleted = FALSE
            """,
            request.title().trim(),
            slug,
            blankToNull(request.summary()),
            blankToNull(request.coverUrl()),
            categoryId,
            request.contentMarkdown(),
            status,
            stats.wordCount(),
            stats.readingMinutes(),
            publishedAt,
            Boolean.TRUE.equals(request.isTop()),
            id
        );

        if (updated == 0) {
            throw new EmptyResultDataAccessException("Article not found", 1);
        }

        syncTags(id, request.tags());
        return ApiResponse.success(withTags(findArticle(id)));
    }

    @PutMapping("/{id}/top")
    @Transactional
    public ApiResponse<AdminArticleVO> updateTopStatus(
        @PathVariable Long id,
        @RequestBody TopStatusRequest request
    ) {
        ensureTopColumn();
        int updated = jdbcTemplate.update("""
            UPDATE article
            SET is_top = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ? AND deleted = FALSE
            """, Boolean.TRUE.equals(request.isTop()), id);

        if (updated == 0) {
            throw new EmptyResultDataAccessException("Article not found", 1);
        }

        return ApiResponse.success(withTags(findArticle(id)));
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ApiResponse<Void> deleteArticle(@PathVariable Long id) {
        jdbcTemplate.update("DELETE FROM article_tag WHERE article_id = ?", id);
        int updated = jdbcTemplate.update("""
            UPDATE article
            SET deleted = TRUE,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ? AND deleted = FALSE
            """, id);

        if (updated == 0) {
            throw new EmptyResultDataAccessException("Article not found", 1);
        }

        return ApiResponse.success(null);
    }

    private AdminArticleVO findArticle(Long id) {
        ensureTopColumn();
        return jdbcTemplate.queryForObject("""
            SELECT a.id, a.title, a.slug, a.summary, a.cover_url, a.category_id,
                   COALESCE(c.name, '未分类') AS category_name,
                   a.content_markdown, a.status, a.word_count, a.reading_minutes,
                   a.published_at, a.created_at, a.updated_at, a.is_top
            FROM article a
            LEFT JOIN category c ON c.id = a.category_id
            WHERE a.id = ? AND a.deleted = FALSE
            """, ARTICLE_MAPPER, id);
    }

    private AdminArticleVO withTags(AdminArticleVO article) {
        List<String> tags = jdbcTemplate.queryForList("""
            SELECT t.name
            FROM tag t
            JOIN article_tag at ON at.tag_id = t.id
            WHERE at.article_id = ?
            ORDER BY t.name
            """, String.class, article.id());

        return new AdminArticleVO(
            article.id(),
            article.title(),
            article.slug(),
            article.summary(),
            article.coverUrl(),
            article.categoryId(),
            article.categoryName(),
            article.contentMarkdown(),
            article.status(),
            article.wordCount(),
            article.readingMinutes(),
            article.publishedAt(),
            article.createdAt(),
            article.updatedAt(),
            article.isTop(),
            tags
        );
    }

    private void ensureTopColumn() {
        jdbcTemplate.execute("ALTER TABLE article ADD COLUMN IF NOT EXISTS is_top BOOLEAN NOT NULL DEFAULT FALSE");
    }

    private void syncTags(Long articleId, List<String> tags) {
        jdbcTemplate.update("DELETE FROM article_tag WHERE article_id = ?", articleId);
        if (tags == null || tags.isEmpty()) {
            return;
        }

        List<String> normalizedTags = tags.stream()
            .filter(Objects::nonNull)
            .map(String::trim)
            .filter(tag -> !tag.isEmpty())
            .distinct()
            .limit(12)
            .toList();

        for (String tag : normalizedTags) {
            String slug = normalizeSlug(tag, tag);
            Long tagId = jdbcTemplate.queryForObject("""
                INSERT INTO tag (name, slug)
                VALUES (?, ?)
                ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, updated_at = CURRENT_TIMESTAMP
                RETURNING id
                """, Long.class, tag, slug);

            jdbcTemplate.update("""
                INSERT INTO article_tag (article_id, tag_id)
                VALUES (?, ?)
                ON CONFLICT DO NOTHING
                """, articleId, tagId);
        }
    }

    private Timestamp publishedAtForUpdate(Long id, String status) {
        if (!"PUBLISHED".equals(status)) {
            return null;
        }

        Timestamp existing = jdbcTemplate.queryForObject(
            "SELECT published_at FROM article WHERE id = ?",
            Timestamp.class,
            id
        );
        return existing == null ? Timestamp.from(OffsetDateTime.now().toInstant()) : existing;
    }

    private Long resolveCategoryId(AdminArticleRequest request) {
        Long manualCategoryId = existingCategoryId(request.categoryId());
        boolean shouldAutoClassify = Boolean.TRUE.equals(request.autoCategory()) || manualCategoryId == null;
        if (!shouldAutoClassify) {
            return manualCategoryId;
        }

        Long inferredCategoryId = inferCategoryId(request);
        return inferredCategoryId == null ? manualCategoryId : inferredCategoryId;
    }

    private Long existingCategoryId(Long categoryId) {
        if (categoryId == null) {
            return null;
        }

        List<Long> ids = jdbcTemplate.queryForList(
            "SELECT id FROM category WHERE id = ?",
            Long.class,
            categoryId
        );
        return ids.isEmpty() ? null : ids.get(0);
    }

    private Long inferCategoryId(AdminArticleRequest request) {
        String text = String.join(" ",
            nullToBlank(request.title()),
            nullToBlank(request.summary()),
            nullToBlank(request.contentMarkdown()),
            request.tags() == null ? "" : String.join(" ", request.tags())
        ).toLowerCase(Locale.ROOT);

        if (containsAny(text, "深度学习", "神经网络", "transformer", "attention", "cnn", "diffusion", "pytorch", "机器学习")) {
            return findOrCreateCategory("deep-learning", "深度学习", "神经网络、模型训练与 AI 研究笔记", 20);
        }
        if (containsAny(text, "java", "spring", "nuxt", "vue", "python", "编程", "代码", "后端", "前端", "fastapi")) {
            return findOrCreateCategory("programming", "编程", "工程开发、代码实践与环境配置", 10);
        }
        if (containsAny(text, "名言", "格言", "赏析", "孔子", "论语", "苏格拉底", "爱因斯坦", "罗素")) {
            return findOrCreateCategory("quote-notes", "名言赏析", "名人名言、句子摘录与短评", 50);
        }
        if (containsAny(text, "读书", "阅读", "书评", "笔记", "札记")) {
            return findOrCreateCategory("reading-notes", "读书札记", "阅读记录与知识整理", 40);
        }
        if (containsAny(text, "生活", "校园", "旅行", "日常", "随笔")) {
            return findOrCreateCategory("life", "生活", "日常记录、校园生活与随笔", 60);
        }
        return findOrCreateCategory("blog", "博客", "博客写作与站点记录", 30);
    }

    private Long findOrCreateCategory(String slug, String name, String description, int sort) {
        return jdbcTemplate.queryForObject("""
            INSERT INTO category (name, slug, description, sort)
            VALUES (?, ?, ?, ?)
            ON CONFLICT (slug) DO UPDATE
            SET name = EXCLUDED.name,
                description = EXCLUDED.description,
                sort = EXCLUDED.sort,
                updated_at = CURRENT_TIMESTAMP
            RETURNING id
            """, Long.class, name, slug, description, sort);
    }

    private boolean containsAny(String text, String... keywords) {
        for (String keyword : keywords) {
            if (text.contains(keyword.toLowerCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }

    private ArticleStats calculateStats(String markdown) {
        int wordCount = 0;
        var matcher = WORD_PATTERN.matcher(markdown == null ? "" : markdown);
        while (matcher.find()) {
            wordCount++;
        }
        int readingMinutes = Math.max(1, (int) Math.ceil(wordCount / 220.0));
        return new ArticleStats(wordCount, readingMinutes);
    }

    private String normalizeStatus(String status) {
        String normalized = status == null ? "DRAFT" : status.trim().toUpperCase(Locale.ROOT);
        return "PUBLISHED".equals(normalized) ? "PUBLISHED" : "DRAFT";
    }

    private String normalizeSlug(String slug, String fallback) {
        String source = blankToNull(slug) == null ? fallback : slug;
        String normalized = source.toLowerCase(Locale.ROOT)
            .replaceAll("[^\\p{L}\\p{N}]+", "-")
            .replaceAll("(^-|-$)", "");
        return normalized.isBlank() ? "article-" + System.currentTimeMillis() : normalized;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static String nullToBlank(String value) {
        return value == null ? "" : value;
    }

    private static Long nullableLong(Object value) {
        return value == null ? null : ((Number) value).longValue();
    }

    private static OffsetDateTime toOffsetDateTime(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant().atOffset(OffsetDateTime.now().getOffset());
    }

    private record ArticleStats(int wordCount, int readingMinutes) {
    }

    private record TopStatusRequest(Boolean isTop) {
    }
}
