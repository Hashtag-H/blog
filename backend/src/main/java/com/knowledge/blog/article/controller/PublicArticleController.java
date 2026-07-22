package com.knowledge.blog.article.controller;

import com.knowledge.blog.article.vo.PublicArticleSummaryVO;
import com.knowledge.blog.article.vo.PublicArticleDetailVO;
import com.knowledge.blog.common.api.ApiResponse;
import com.knowledge.blog.common.api.PageResponse;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.List;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("/api/public/articles")
public class PublicArticleController {

    private final JdbcTemplate jdbcTemplate;

    public PublicArticleController(ObjectProvider<JdbcTemplate> jdbcTemplateProvider) {
        this.jdbcTemplate = jdbcTemplateProvider.getIfAvailable();
    }

    @GetMapping
    public ApiResponse<PageResponse<PublicArticleSummaryVO>> listArticles(
        @RequestParam(defaultValue = "1") int page,
        @RequestParam(defaultValue = "20") int pageSize
    ) {
        int safePage = Math.max(page, 1);
        int safePageSize = Math.min(Math.max(pageSize, 1), 20);

        if (jdbcTemplate == null) {
            return ApiResponse.success(paginateFallback(safePage, safePageSize));
        }

        ensureTopColumn();
        Long total = jdbcTemplate.queryForObject("""
            SELECT COUNT(*)
            FROM article
            WHERE deleted = FALSE AND status = 'PUBLISHED'
            """, Long.class);

        if (total == null || total == 0) {
            return ApiResponse.success(paginateFallback(safePage, safePageSize));
        }

        int offset = (safePage - 1) * safePageSize;
        List<PublicArticleSummaryVO> articles = jdbcTemplate.query("""
            SELECT a.id, a.title, a.slug, a.summary, a.cover_url, a.reading_minutes,
                   a.published_at, a.is_top, COALESCE(c.name, '未分类') AS category
            FROM article a
            LEFT JOIN category c ON c.id = a.category_id
            WHERE a.deleted = FALSE AND a.status = 'PUBLISHED'
            ORDER BY a.is_top DESC, a.published_at DESC, a.updated_at DESC
            LIMIT ? OFFSET ?
            """, (rs, rowNum) -> new PublicArticleSummaryVO(
                rs.getString("title"),
                rs.getString("slug"),
                rs.getString("summary"),
                rs.getString("category"),
                tagsForArticle(rs.getLong("id")),
                toLocalDate(rs.getTimestamp("published_at")),
                rs.getInt("reading_minutes"),
                rs.getString("cover_url") == null ? "/images/henan-wheatfield-bg.png" : rs.getString("cover_url"),
                rs.getBoolean("is_top")
            ), safePageSize, offset);

        return ApiResponse.success(new PageResponse<>(articles, total, safePage, safePageSize));
    }

    @GetMapping("/{slug}")
    public ApiResponse<PublicArticleDetailVO> getArticle(@PathVariable String slug) {
        ensureTopColumn();
        if (jdbcTemplate == null) {
            return fallbackDetail(slug)
                .map(ApiResponse::success)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Article not found"));
        }

        try {
            PublicArticleDetailVO article = jdbcTemplate.queryForObject("""
                SELECT a.id, a.title, a.slug, a.summary, a.cover_url, a.content_markdown, a.content_html,
                       a.reading_minutes, a.published_at, COALESCE(c.name, '未分类') AS category
                FROM article a
                LEFT JOIN category c ON c.id = a.category_id
                WHERE a.slug = ? AND a.deleted = FALSE AND a.status = 'PUBLISHED'
                """, (rs, rowNum) -> new PublicArticleDetailVO(
                    rs.getString("title"),
                    rs.getString("slug"),
                    rs.getString("summary"),
                    rs.getString("category"),
                    tagsForArticle(rs.getLong("id")),
                    toLocalDate(rs.getTimestamp("published_at")),
                    rs.getInt("reading_minutes"),
                    rs.getString("cover_url") == null ? "/images/henan-wheatfield-bg.png" : rs.getString("cover_url"),
                    rs.getString("content_markdown"),
                    rs.getString("content_html")
                ), slug);
            return ApiResponse.success(article);
        } catch (EmptyResultDataAccessException ex) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Article not found");
        }
    }

    private List<String> tagsForArticle(Long articleId) {
        if (jdbcTemplate == null) {
            return List.of();
        }
        return jdbcTemplate.queryForList("""
            SELECT t.name
            FROM tag t
            JOIN article_tag at ON at.tag_id = t.id
            WHERE at.article_id = ?
            ORDER BY t.name
            """, String.class, articleId);
    }

    private void ensureTopColumn() {
        if (jdbcTemplate != null) {
            jdbcTemplate.execute("ALTER TABLE article ADD COLUMN IF NOT EXISTS is_top BOOLEAN NOT NULL DEFAULT FALSE");
        }
    }

    private LocalDate toLocalDate(Timestamp timestamp) {
        return timestamp == null ? LocalDate.now() : timestamp.toLocalDateTime().toLocalDate();
    }

    private List<PublicArticleSummaryVO> fallbackArticles() {
        return List.of(
            new PublicArticleSummaryVO(
                "XDU-STE 研究生生存手册",
                "xdu-ste-guide",
                "西电通院研究生生存手册，包含课程资料、培养相关、选课、期末、生活相关、好物推荐等内容。",
                "学习资料",
                List.of("研究生", "西电", "课程"),
                LocalDate.of(2025, 7, 7),
                12,
                "/images/henan-wheatfield-bg.png",
                true
            ),
            new PublicArticleSummaryVO(
                "Live2D AI 聊天功能配置教程",
                "live2d-ai-chat",
                "基于 FastAPI 与 DeepSeek 的 AI 博客伴侣配置过程，覆盖上下文对话、Markdown 渲染与全站检索。",
                "AI 实践",
                List.of("Live2D", "FastAPI", "DeepSeek"),
                LocalDate.of(2026, 2, 27),
                9,
                "/images/sakura-bg.jpg",
                true
            ),
            new PublicArticleSummaryVO(
                "西电网络信息论知识清单",
                "network-information-theory",
                "整理信息论基础、多址接入、广播信道、相关信源编码、中继信道与干扰信道等课程知识点。",
                "课程笔记",
                List.of("信息论", "通信", "复习"),
                LocalDate.of(2026, 6, 25),
                15,
                "/images/henan-wheatfield-bg.png",
                false
            ),
            new PublicArticleSummaryVO(
                "AI 驱动的个人知识博客与学习管理平台",
                "ai-knowledge-blog",
                "一个用于写作、知识管理、智能延伸阅读和学习计划管理的个人博客平台。",
                "项目开发",
                List.of("全栈", "知识库", "学习管理"),
                LocalDate.of(2026, 7, 14),
                10,
                "/images/sakura-bg.jpg",
                false
            )
        );
    }

    private PageResponse<PublicArticleSummaryVO> paginateFallback(int page, int pageSize) {
        List<PublicArticleSummaryVO> articles = fallbackArticles();
        int fromIndex = Math.min((page - 1) * pageSize, articles.size());
        int toIndex = Math.min(fromIndex + pageSize, articles.size());
        return new PageResponse<>(articles.subList(fromIndex, toIndex), articles.size(), page, pageSize);
    }

    private java.util.Optional<PublicArticleDetailVO> fallbackDetail(String slug) {
        return fallbackArticles().stream()
            .filter(article -> article.slug().equals(slug))
            .findFirst()
            .map(article -> new PublicArticleDetailVO(
                article.title(),
                article.slug(),
                article.summary(),
                article.category(),
                article.tags(),
                article.publishedAt(),
                article.readingMinutes(),
                article.cover(),
                article.summary(),
                null
            ));
    }
}

