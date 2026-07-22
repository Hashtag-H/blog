package com.knowledge.blog.category.controller;

import com.knowledge.blog.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.sql.Timestamp;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/categories")
public class AdminCategoryController {

    private final JdbcTemplate jdbcTemplate;

    public AdminCategoryController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public ApiResponse<List<CategoryVO>> listCategories() {
        return ApiResponse.success(jdbcTemplate.query("""
            SELECT c.id, c.name, c.slug, c.description, c.sort,
                   COUNT(a.id) AS article_count,
                   c.created_at, c.updated_at
            FROM category c
            LEFT JOIN article a ON a.category_id = c.id AND a.deleted = FALSE
            GROUP BY c.id
            ORDER BY c.sort ASC, c.name ASC
            """, (rs, rowNum) -> new CategoryVO(
            rs.getLong("id"),
            rs.getString("name"),
            rs.getString("slug"),
            rs.getString("description"),
            rs.getInt("sort"),
            rs.getInt("article_count"),
            toOffsetDateTime(rs.getTimestamp("created_at")),
            toOffsetDateTime(rs.getTimestamp("updated_at"))
        )));
    }

    @PostMapping
    @Transactional
    public ApiResponse<CategoryVO> createCategory(@Valid @RequestBody CategoryRequest request) {
        String slug = normalizeSlug(request.slug(), request.name());
        Long id = jdbcTemplate.queryForObject("""
            INSERT INTO category (name, slug, description, sort)
            VALUES (?, ?, ?, ?)
            RETURNING id
            """, Long.class, request.name().trim(), slug, blankToNull(request.description()), safeSort(request.sort()));
        return ApiResponse.success(findCategory(id));
    }

    @PutMapping("/{id}")
    @Transactional
    public ApiResponse<CategoryVO> updateCategory(
        @PathVariable Long id,
        @Valid @RequestBody CategoryRequest request
    ) {
        int updated = jdbcTemplate.update("""
            UPDATE category
            SET name = ?,
                slug = ?,
                description = ?,
                sort = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
            """,
            request.name().trim(),
            normalizeSlug(request.slug(), request.name()),
            blankToNull(request.description()),
            safeSort(request.sort()),
            id
        );
        if (updated == 0) {
            throw new EmptyResultDataAccessException("Category not found", 1);
        }
        return ApiResponse.success(findCategory(id));
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ApiResponse<Void> deleteCategory(@PathVariable Long id) {
        jdbcTemplate.update("UPDATE article SET category_id = NULL, updated_at = CURRENT_TIMESTAMP WHERE category_id = ?", id);
        int deleted = jdbcTemplate.update("DELETE FROM category WHERE id = ?", id);
        if (deleted == 0) {
            throw new EmptyResultDataAccessException("Category not found", 1);
        }
        return ApiResponse.success(null);
    }

    private CategoryVO findCategory(Long id) {
        return jdbcTemplate.queryForObject("""
            SELECT c.id, c.name, c.slug, c.description, c.sort,
                   COUNT(a.id) AS article_count,
                   c.created_at, c.updated_at
            FROM category c
            LEFT JOIN article a ON a.category_id = c.id AND a.deleted = FALSE
            WHERE c.id = ?
            GROUP BY c.id
            """, (rs, rowNum) -> new CategoryVO(
            rs.getLong("id"),
            rs.getString("name"),
            rs.getString("slug"),
            rs.getString("description"),
            rs.getInt("sort"),
            rs.getInt("article_count"),
            toOffsetDateTime(rs.getTimestamp("created_at")),
            toOffsetDateTime(rs.getTimestamp("updated_at"))
        ), id);
    }

    private String normalizeSlug(String slug, String fallback) {
        String source = blankToNull(slug) == null ? fallback : slug;
        String normalized = source.toLowerCase(Locale.ROOT)
            .replaceAll("[^\\p{L}\\p{N}]+", "-")
            .replaceAll("(^-|-$)", "");
        return normalized.isBlank() ? "category-" + System.currentTimeMillis() : normalized;
    }

    private int safeSort(Integer sort) {
        return sort == null ? 0 : sort;
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static OffsetDateTime toOffsetDateTime(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant().atOffset(OffsetDateTime.now().getOffset());
    }

    public record CategoryRequest(
        @NotBlank(message = "分类名称不能为空")
        @Size(max = 80, message = "分类名称不能超过 80 个字符")
        String name,

        @Size(max = 120, message = "Slug 不能超过 120 个字符")
        String slug,

        @Size(max = 500, message = "分类描述不能超过 500 个字符")
        String description,

        Integer sort
    ) {
    }

    public record CategoryVO(
        Long id,
        String name,
        String slug,
        String description,
        Integer sort,
        Integer articleCount,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt
    ) {
    }
}
