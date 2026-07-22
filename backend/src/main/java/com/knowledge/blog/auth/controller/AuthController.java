package com.knowledge.blog.auth.controller;

import com.knowledge.blog.auth.dto.LoginRequest;
import com.knowledge.blog.auth.vo.LoginResponse;
import com.knowledge.blog.common.api.ApiResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final String adminUsername;
    private final String adminPassword;
    private final String adminToken;
    private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder passwordEncoder;

    public AuthController(
        @Value("${app.admin.username}") String adminUsername,
        @Value("${app.admin.password}") String adminPassword,
        @Value("${app.admin.token}") String adminToken,
        JdbcTemplate jdbcTemplate,
        PasswordEncoder passwordEncoder
    ) {
        this.adminUsername = adminUsername;
        this.adminPassword = adminPassword;
        this.adminToken = adminToken;
        this.jdbcTemplate = jdbcTemplate;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        if (matchesDatabaseUser(request)) {
            jdbcTemplate.update(
                "UPDATE admin_user SET last_login_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE username = ?",
                request.username()
            );
            return ApiResponse.success(new LoginResponse(adminToken, request.username()));
        }

        if (!adminUsername.equals(request.username()) || !adminPassword.equals(request.password())) {
            throw new IllegalArgumentException("用户名或密码错误");
        }
        return ApiResponse.success(new LoginResponse(adminToken, adminUsername));
    }

    private boolean matchesDatabaseUser(LoginRequest request) {
        List<String> hashes = jdbcTemplate.queryForList("""
            SELECT password_hash
            FROM admin_user
            WHERE username = ? AND enabled = TRUE AND deleted = FALSE
            LIMIT 1
            """, String.class, request.username());

        if (hashes.isEmpty()) {
            return false;
        }

        String hash = hashes.get(0);
        return looksLikeBCrypt(hash) && passwordEncoder.matches(request.password(), hash);
    }

    private boolean looksLikeBCrypt(String hash) {
        return hash != null && hash.matches("\\$2[aby]\\$\\d{2}\\$.{53}");
    }
}
