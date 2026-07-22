package com.knowledge.blog.article.vo;

import java.time.LocalDate;
import java.util.List;

public record PublicArticleSummaryVO(
    String title,
    String slug,
    String summary,
    String category,
    List<String> tags,
    LocalDate publishedAt,
    int readingMinutes,
    String cover,
    boolean isTop
) {
}
