package com.knowledge.blog.article.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

public record AdminArticleRequest(
    @NotBlank(message = "标题不能为空")
    @Size(max = 220, message = "标题不能超过 220 个字符")
    String title,

    @Size(max = 240, message = "Slug 不能超过 240 个字符")
    String slug,

    @Size(max = 1000, message = "摘要不能超过 1000 个字符")
    String summary,

    @Size(max = 500, message = "封面地址不能超过 500 个字符")
    String coverUrl,

    Long categoryId,

    Boolean autoCategory,

    @NotBlank(message = "Markdown 内容不能为空")
    String contentMarkdown,

    String status,

    Boolean isTop,

    List<String> tags
) {
}
