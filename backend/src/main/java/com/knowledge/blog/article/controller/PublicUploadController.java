package com.knowledge.blog.article.controller;

import java.net.MalformedURLException;
import java.nio.file.Path;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/public/uploads")
public class PublicUploadController {

    private final Path storageRoot;

    public PublicUploadController(@Value("${app.upload.storage-dir:storage/uploads}") String storageDir) {
        this.storageRoot = Path.of(storageDir).toAbsolutePath().normalize();
    }

    @GetMapping("/images/{year}/{month}/{day}/{filename:.+}")
    public ResponseEntity<Resource> getImage(
        @PathVariable String year,
        @PathVariable String month,
        @PathVariable String day,
        @PathVariable String filename
    ) throws MalformedURLException {
        Path imagePath = storageRoot.resolve("images").resolve(year).resolve(month).resolve(day).resolve(filename)
            .normalize();
        if (!imagePath.startsWith(storageRoot)) {
            return ResponseEntity.notFound().build();
        }

        Resource resource = new UrlResource(imagePath.toUri());
        if (!resource.exists() || !resource.isReadable()) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok()
            .cacheControl(CacheControl.noCache())
            .body(resource);
    }
}
