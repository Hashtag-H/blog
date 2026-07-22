package com.knowledge.blog.setting.controller;

import com.knowledge.blog.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/settings")
public class AdminSettingsController {

    private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder passwordEncoder;
    private final String fallbackUsername;
    private final String fallbackPassword;

    public AdminSettingsController(
        JdbcTemplate jdbcTemplate,
        PasswordEncoder passwordEncoder,
        @Value("${app.admin.username}") String fallbackUsername,
        @Value("${app.admin.password}") String fallbackPassword
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.passwordEncoder = passwordEncoder;
        this.fallbackUsername = fallbackUsername;
        this.fallbackPassword = fallbackPassword;
    }

    @GetMapping("/site")
    public ApiResponse<SiteSettingsVO> getSiteSettings() {
        ensureSiteSettingTable();
        return ApiResponse.success(readSiteSettings());
    }

    @PutMapping("/site")
    @Transactional
    public ApiResponse<SiteSettingsVO> updateSiteSettings(@Valid @RequestBody SiteSettingsRequest request) {
        ensureSiteSettingTable();
        Map<String, String> values = new LinkedHashMap<>();
        values.put("siteTitle", blankToDefault(request.siteTitle(), "河南娃的小窝"));
        values.put("displayName", blankToDefault(request.displayName(), "河南娃"));
        values.put("motto", blankToDefault(request.motto(), "愿麦浪祝颂你的旅途"));
        values.put("avatarUrl", blankToDefault(request.avatarUrl(), "/images/profile-id.webp"));
        values.put("backgroundUrl", blankToDefault(request.backgroundUrl(), "/images/henan-wheatfield-bg.png"));
        values.put("announcement", blankToDefault(request.announcement(), "欢迎来到河南娃的小窝！这里会记录编程、深度学习、读书和麦田里的灵光。"));
        values.put("githubUrl", blankToDefault(request.githubUrl(), "https://github.com/"));
        values.put("rssUrl", blankToDefault(request.rssUrl(), "/rss.xml"));
        values.put("live2dEnabled", String.valueOf(request.live2dEnabled() == null || request.live2dEnabled()));
        values.put("live2dCdnPath", blankToDefault(
            request.live2dCdnPath(),
            "https://fastly.jsdelivr.net/gh/fghrsh/live2d_api@1.0.1/"
        ));
        values.put("live2dModelId", normalizeIndex(request.live2dModelId()));
        values.put("live2dTextureId", normalizeIndex(request.live2dTextureId()));

        values.forEach((key, value) -> jdbcTemplate.update("""
            INSERT INTO site_setting (key, value)
            VALUES (?, ?)
            ON CONFLICT (key) DO UPDATE
            SET value = EXCLUDED.value,
                updated_at = CURRENT_TIMESTAMP
            """, key, value));

        return ApiResponse.success(readSiteSettings());
    }

    @GetMapping("/account")
    public ApiResponse<AccountProfileVO> getAccount() {
        return ApiResponse.success(readAccountProfile());
    }

    @PutMapping("/account")
    @Transactional
    public ApiResponse<AccountProfileVO> updateAccount(@Valid @RequestBody AccountProfileRequest request) {
        Long id = currentAdminId();
        if (id == null) {
            jdbcTemplate.update("""
                INSERT INTO admin_user (username, password_hash, display_name, email)
                VALUES (?, ?, ?, ?)
                """,
                request.username().trim(),
                passwordEncoder.encode(fallbackPassword),
                request.displayName().trim(),
                blankToNull(request.email())
            );
        } else {
            jdbcTemplate.update("""
                UPDATE admin_user
                SET username = ?,
                    display_name = ?,
                    email = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """,
                request.username().trim(),
                request.displayName().trim(),
                blankToNull(request.email()),
                id
            );
        }
        return ApiResponse.success(readAccountProfile());
    }

    @PutMapping("/account/password")
    @Transactional
    public ApiResponse<Void> updatePassword(@Valid @RequestBody PasswordRequest request) {
        if (request.newPassword().length() < 8) {
            throw new IllegalArgumentException("新密码至少需要 8 位");
        }

        Long id = currentAdminId();
        AccountProfileVO profile = readAccountProfile();
        String username = blankToDefault(request.username(), profile.username());
        if (id == null) {
            if (!fallbackPassword.equals(request.currentPassword())) {
                throw new IllegalArgumentException("当前密码错误");
            }
            jdbcTemplate.update("""
                INSERT INTO admin_user (username, password_hash, display_name, email)
                VALUES (?, ?, ?, ?)
                """,
                username,
                passwordEncoder.encode(request.newPassword()),
                profile.displayName(),
                profile.email()
            );
            return ApiResponse.success(null);
        }

        String hash = jdbcTemplate.queryForObject(
            "SELECT password_hash FROM admin_user WHERE id = ?",
            String.class,
            id
        );
        boolean matchesStored = looksLikeBCrypt(hash) && passwordEncoder.matches(request.currentPassword(), hash);
        boolean matchesFallback = fallbackUsername.equals(profile.username()) && fallbackPassword.equals(request.currentPassword());
        if (!matchesStored && !matchesFallback) {
            throw new IllegalArgumentException("当前密码错误");
        }

        jdbcTemplate.update("""
            UPDATE admin_user
            SET username = ?,
                password_hash = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
            """, username, passwordEncoder.encode(request.newPassword()), id);
        return ApiResponse.success(null);
    }

    private SiteSettingsVO readSiteSettings() {
        Map<String, String> values = defaultSettings();
        List<Map<String, Object>> rows = jdbcTemplate.queryForList("SELECT key, value FROM site_setting");
        for (Map<String, Object> row : rows) {
            values.put(String.valueOf(row.get("key")), String.valueOf(row.get("value")));
        }
        return new SiteSettingsVO(
            values.get("siteTitle"),
            values.get("displayName"),
            values.get("motto"),
            values.get("avatarUrl"),
            values.get("backgroundUrl"),
            values.get("announcement"),
            values.get("githubUrl"),
            values.get("rssUrl"),
            Boolean.parseBoolean(values.get("live2dEnabled")),
            values.get("live2dCdnPath"),
            parseIndex(values.get("live2dModelId")),
            parseIndex(values.get("live2dTextureId"))
        );
    }

    private AccountProfileVO readAccountProfile() {
        List<AccountProfileVO> rows = jdbcTemplate.query("""
            SELECT username, display_name, email
            FROM admin_user
            WHERE deleted = FALSE
            ORDER BY id ASC
            LIMIT 1
            """, (rs, rowNum) -> new AccountProfileVO(
            rs.getString("username"),
            rs.getString("display_name"),
            rs.getString("email")
        ));
        return rows.isEmpty() ? new AccountProfileVO(fallbackUsername, "管理员", null) : rows.get(0);
    }

    private Long currentAdminId() {
        List<Long> ids = jdbcTemplate.queryForList("""
            SELECT id
            FROM admin_user
            WHERE deleted = FALSE
            ORDER BY id ASC
            LIMIT 1
            """, Long.class);
        return ids.isEmpty() ? null : ids.get(0);
    }

    private void ensureSiteSettingTable() {
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS site_setting (
              key VARCHAR(100) PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """);
    }

    private Map<String, String> defaultSettings() {
        Map<String, String> values = new LinkedHashMap<>();
        values.put("siteTitle", "河南娃的小窝");
        values.put("displayName", "河南娃");
        values.put("motto", "愿麦浪祝颂你的旅途");
        values.put("avatarUrl", "/images/profile-id.webp");
        values.put("backgroundUrl", "/images/henan-wheatfield-bg.png");
        values.put("announcement", "欢迎来到河南娃的小窝！这里会记录编程、深度学习、读书和麦田里的灵光。");
        values.put("githubUrl", "https://github.com/");
        values.put("rssUrl", "/rss.xml");
        values.put("live2dEnabled", "true");
        values.put("live2dCdnPath", "https://fastly.jsdelivr.net/gh/fghrsh/live2d_api@1.0.1/");
        values.put("live2dModelId", "0");
        values.put("live2dTextureId", "0");
        return values;
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private String normalizeIndex(Integer value) {
        return String.valueOf(value == null || value < 0 ? 0 : value);
    }

    private int parseIndex(String value) {
        try {
            return Math.max(0, Integer.parseInt(value));
        } catch (NumberFormatException ex) {
            return 0;
        }
    }

    private boolean looksLikeBCrypt(String hash) {
        return hash != null && hash.matches("\\$2[aby]\\$\\d{2}\\$.{53}");
    }

    public record SiteSettingsRequest(
        @Size(max = 100, message = "站点标题不能超过 100 个字符")
        String siteTitle,
        @Size(max = 100, message = "前台昵称不能超过 100 个字符")
        String displayName,
        @Size(max = 160, message = "签名不能超过 160 个字符")
        String motto,
        @Size(max = 500, message = "头像地址不能超过 500 个字符")
        String avatarUrl,
        @Size(max = 500, message = "背景地址不能超过 500 个字符")
        String backgroundUrl,
        @Size(max = 1000, message = "公告不能超过 1000 个字符")
        String announcement,
        @Size(max = 500, message = "GitHub 地址不能超过 500 个字符")
        String githubUrl,
        @Size(max = 500, message = "RSS 地址不能超过 500 个字符")
        String rssUrl,
        Boolean live2dEnabled,
        @Size(max = 500, message = "Live2D 模型源不能超过 500 个字符")
        String live2dCdnPath,
        Integer live2dModelId,
        Integer live2dTextureId
    ) {
    }

    public record SiteSettingsVO(
        String siteTitle,
        String displayName,
        String motto,
        String avatarUrl,
        String backgroundUrl,
        String announcement,
        String githubUrl,
        String rssUrl,
        Boolean live2dEnabled,
        String live2dCdnPath,
        Integer live2dModelId,
        Integer live2dTextureId
    ) {
    }

    public record AccountProfileRequest(
        @NotBlank(message = "用户名不能为空")
        @Size(max = 64, message = "用户名不能超过 64 个字符")
        String username,
        @NotBlank(message = "显示名不能为空")
        @Size(max = 100, message = "显示名不能超过 100 个字符")
        String displayName,
        @Size(max = 180, message = "邮箱不能超过 180 个字符")
        String email
    ) {
    }

    public record PasswordRequest(
        @Size(max = 64, message = "用户名不能超过 64 个字符")
        String username,
        @NotBlank(message = "当前密码不能为空")
        String currentPassword,
        @NotBlank(message = "新密码不能为空")
        String newPassword
    ) {
    }

    public record AccountProfileVO(String username, String displayName, String email) {
    }
}
