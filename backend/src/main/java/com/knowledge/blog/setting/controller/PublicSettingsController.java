package com.knowledge.blog.setting.controller;

import com.knowledge.blog.common.api.ApiResponse;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/public/settings")
public class PublicSettingsController {

    private final JdbcTemplate jdbcTemplate;

    public PublicSettingsController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/site")
    public ApiResponse<SiteSettingsVO> getSiteSettings() {
        ensureSiteSettingTable();
        Map<String, String> values = defaultSettings();
        jdbcTemplate.queryForList("SELECT key, value FROM site_setting").forEach(row ->
            values.put(String.valueOf(row.get("key")), String.valueOf(row.get("value")))
        );
        return ApiResponse.success(new SiteSettingsVO(
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
        ));
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

    private int parseIndex(String value) {
        try {
            return Math.max(0, Integer.parseInt(value));
        } catch (NumberFormatException ex) {
            return 0;
        }
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
}
