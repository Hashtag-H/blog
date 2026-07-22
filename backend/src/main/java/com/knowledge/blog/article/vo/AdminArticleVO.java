package com.knowledge.blog.article.vo;

import java.time.OffsetDateTime;
import java.util.List;

public record AdminArticleVO(
    Long id,
    String title,
    String slug,
    String summary,
    String coverUrl,
    Long categoryId,
    String categoryName,
    String contentMarkdown,
    String status,
    int wordCount,
    int readingMinutes,
    OffsetDateTime publishedAt,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt,
    boolean isTop,
    List<String> tags
) {
}
