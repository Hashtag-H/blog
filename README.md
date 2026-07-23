# Blog Hexo

这是一个基于 Hexo + Butterfly 主题的个人博客项目，并配套了一个 Windows 本地文章管理器 `BlogManager.exe`，用于更方便地管理、预览、编辑和发布文章。

远程仓库原来的 `main` 内容已保留在分支：

```text
previous-main-20260723
```

## 功能

- Hexo 博客源码管理
- Butterfly 主题配置
- 本地文章管理器 `BlogManager.exe`
- 新建文章自动生成规范 Front Matter
- 从现有文章中选择分类和标签
- 封面图片可从文件管理器选择，并自动复制到 `source/images/uploads`
- 内置 Markdown 快速预览
- 一键用 Typora 打开文章
- 一键生成本地预览
- 一键执行 `deploy-baota.bat` 发布到宝塔服务器

## 目录

```text
source/_posts/                  博客文章
source/images/                  图片资源
source/images/uploads/          管理器上传的封面图片
scaffolds/                      Hexo 模板
local-tools/blog-manager/       BlogManager 源码、图标和辅助脚本
BlogManager.exe                 Windows 本地文章管理器
deploy-baota.bat                一键发布脚本
generate-blog.bat               生成博客脚本
start-preview.cmd               启动本地预览
```

## 本地使用

安装依赖：

```bash
pnpm install
```

生成博客：

```bash
pnpm run build
```

启动 Hexo 服务：

```bash
pnpm run server
```

也可以直接双击：

```text
BlogManager.exe
```

## BlogManager

`BlogManager.exe` 是用 C# WinForms 写的本地桌面工具。

源码：

```text
local-tools/blog-manager/BlogManager.cs
```

重新编译：

```bat
build-blog-manager.bat
```

图标源文件：

```text
local-tools/blog-manager/BlogManagerIcon.svg
```

生成 `.ico`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\local-tools\blog-manager\create-icon.ps1
```

## 新建文章 Front Matter

管理器新建文章时会自动生成类似内容：

```yaml
---
title: "文章标题"
date: "2026-07-23 12:00:00"
updated: "2026-07-23 12:00:00"
categories: ["随笔"]
tags: []
description: ""
cover: "/images/henan-wheatfield-bg.png"
top_img: "/images/henan-wheatfield-bg.png"
sticky: 0
top: false
---
```

如果选择了本地封面图片，图片会复制到：

```text
source/images/uploads/
```

并写入：

```yaml
cover: "/images/uploads/图片名.jpg"
top_img: "/images/uploads/图片名.jpg"
```

## 发布

发布脚本：

```bat
deploy-baota.bat
```

该脚本会调用 PowerShell 发布流程。部署相关的本地配置、SSH key、上传包和生成缓存不会提交到 GitHub。

## 注意

以下内容已加入 `.gitignore`，不会上传：

- `node_modules/`
- `public/`
- `.baota-ssh-key`
- `.baota-deploy.json`
- `.baota-manifest.json`
- `.baota-staging/`
- `baota-upload.zip`
- `baota-upload.tar.gz`
- 日志文件
