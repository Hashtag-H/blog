package com.knowledge.blog.category.controller;

import com.knowledge.blog.common.api.ApiResponse;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/public")
public class PublicTaxonomyController {

    private final JdbcTemplate jdbcTemplate;

    public PublicTaxonomyController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/categories")
    public ApiResponse<List<TaxonomyCountVO>> listCategories() {
        return ApiResponse.success(jdbcTemplate.query("""
            SELECT c.name, c.slug, COUNT(a.id) AS count
            FROM category c
            LEFT JOIN article a ON a.category_id = c.id
                AND a.deleted = FALSE
                AND a.status = 'PUBLISHED'
            GROUP BY c.id
            ORDER BY c.sort ASC, c.name ASC
            """, (rs, rowNum) -> new TaxonomyCountVO(
            rs.getString("name"),
            rs.getString("slug"),
            rs.getInt("count")
        )));
    }

    @GetMapping("/tags")
    public ApiResponse<List<TaxonomyCountVO>> listTags() {
        return ApiResponse.success(jdbcTemplate.query("""
            SELECT t.name, t.slug, COUNT(a.id) AS count
            FROM tag t
            LEFT JOIN article_tag at ON at.tag_id = t.id
            LEFT JOIN article a ON a.id = at.article_id
                AND a.deleted = FALSE
                AND a.status = 'PUBLISHED'
            GROUP BY t.id
            ORDER BY count DESC, t.name ASC
            LIMIT 40
            """, (rs, rowNum) -> new TaxonomyCountVO(
            rs.getString("name"),
            rs.getString("slug"),
            rs.getInt("count")
        )));
    }

    public record TaxonomyCountVO(String name, String slug, int count) {
    }
}
