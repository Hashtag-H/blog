package com.knowledge.blog.auth.vo;

public record LoginResponse(
    String token,
    String username
) {
}
