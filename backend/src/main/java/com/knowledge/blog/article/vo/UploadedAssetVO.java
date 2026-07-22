package com.knowledge.blog.article.vo;

public record UploadedAssetVO(
    String originalFilename,
    String storedFilename,
    String url,
    long size
) {
}
