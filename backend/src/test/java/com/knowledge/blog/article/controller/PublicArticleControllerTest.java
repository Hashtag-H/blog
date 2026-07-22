package com.knowledge.blog.article.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(PublicArticleController.class)
@AutoConfigureMockMvc(addFilters = false)
class PublicArticleControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void listArticlesReturnsDirectoryItems() throws Exception {
        mockMvc.perform(get("/api/public/articles"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(200))
            .andExpect(jsonPath("$.data.total").value(4))
            .andExpect(jsonPath("$.data.page").value(1))
            .andExpect(jsonPath("$.data.pageSize").value(20))
            .andExpect(jsonPath("$.data.records[0].title").value("XDU-STE 研究生生存手册"))
            .andExpect(jsonPath("$.data.records[0].cover").exists())
            .andExpect(jsonPath("$.data.records[0].isTop").value(true));
    }

    @Test
    void listArticlesSupportsPagination() throws Exception {
        mockMvc.perform(get("/api/public/articles?page=2&pageSize=2"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(200))
            .andExpect(jsonPath("$.data.total").value(4))
            .andExpect(jsonPath("$.data.page").value(2))
            .andExpect(jsonPath("$.data.pageSize").value(2))
            .andExpect(jsonPath("$.data.records.length()").value(2));
    }

    @Test
    void getArticleReturnsDetailContent() throws Exception {
        mockMvc.perform(get("/api/public/articles/xdu-ste-guide"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.code").value(200))
            .andExpect(jsonPath("$.data.slug").value("xdu-ste-guide"))
            .andExpect(jsonPath("$.data.contentMarkdown").exists());
    }
}
