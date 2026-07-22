package com.knowledge.blog.article.controller;

import com.knowledge.blog.article.vo.UploadedAssetVO;
import com.knowledge.blog.common.api.ApiResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/admin/uploads")
public class AdminUploadController {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "gif", "webp", "svg");

    private final Path storageRoot;

    public AdminUploadController(@Value("${app.upload.storage-dir:storage/uploads}") String storageDir) {
        this.storageRoot = Path.of(storageDir).toAbsolutePath().normalize();
    }

    @PostMapping(value = "/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<UploadedAssetVO> uploadImage(@RequestPart("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("上传文件不能为空");
        }

        String originalFilename = StringUtils.cleanPath(
            file.getOriginalFilename() == null ? "image" : file.getOriginalFilename()
        );
        String extension = extensionOf(originalFilename);
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new IllegalArgumentException("仅支持 jpg、png、gif、webp、svg 图片");
        }

        LocalDate today = LocalDate.now();
        Path dateDir = storageRoot.resolve("images")
            .resolve(String.valueOf(today.getYear()))
            .resolve(String.format("%02d", today.getMonthValue()))
            .resolve(String.format("%02d", today.getDayOfMonth()))
            .normalize();
        Files.createDirectories(dateDir);

        String storedName = UUID.randomUUID() + "." + extension;
        Path target = dateDir.resolve(storedName).normalize();
        if (!target.startsWith(storageRoot)) {
            throw new IllegalArgumentException("非法文件路径");
        }

        Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        String url = "/api/public/uploads/images/%d/%02d/%02d/%s".formatted(
            today.getYear(),
            today.getMonthValue(),
            today.getDayOfMonth(),
            storedName
        );

        return ApiResponse.success(new UploadedAssetVO(originalFilename, storedName, url, file.getSize()));
    }

    private String extensionOf(String filename) {
        int dotIndex = filename.lastIndexOf('.');
        if (dotIndex < 0 || dotIndex == filename.length() - 1) {
            return "";
        }
        return filename.substring(dotIndex + 1).toLowerCase(Locale.ROOT);
    }
}
