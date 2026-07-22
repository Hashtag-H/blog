# AI 驱动的个人知识博客与学习管理平台

这是一个前后端分离的个人知识博客与学习管理平台，目标是支持文章写作、Markdown 导入、分类标签管理、智能延伸阅读、学习规划和后续 AI 能力扩展。

当前版本完成了第一阶段项目初始化：前后端基础工程、Docker Compose、Nginx、PostgreSQL 初始化脚本、健康检查接口和基础页面骨架。

## 技术栈

前端：

- Nuxt 4
- Vue 3
- TypeScript
- Tailwind CSS
- Pinia

后端：

- Java 17
- Spring Boot 3
- MyBatis-Plus
- Spring Security
- JWT
- PostgreSQL
- Redis
- MinIO
- Maven
- Knife4j / OpenAPI 3

部署：

- Docker
- Docker Compose
- Nginx

## 项目目录

```text
.
├── frontend/              # Nuxt 前端项目
├── backend/               # Spring Boot 后端项目
├── deploy/                # Nginx 等部署配置
├── docs/                  # 文档和数据库脚本
├── docker-compose.yml     # Docker Compose 编排文件
├── .env.example           # 环境变量示例
└── README.md
```

## 本地启用方法

建议先分别启动后端和前端，确认开发环境可用。

### 1. 启动后端

进入后端目录：

```powershell
cd E:\daima_code\大项目\blog\backend
```

运行测试：

```powershell
mvn test
```

启动后端服务：

```powershell
mvn spring-boot:run
```

后端默认地址：

```text
http://localhost:8080
```

健康检查接口：

```text
http://localhost:8080/api/public/health
```

接口文档地址：

```text
http://localhost:8080/doc.html
```

### 2. 启动前端

进入前端目录：

```powershell
cd E:\daima_code\大项目\blog\frontend
```

首次启动前安装依赖：

```powershell
npm install
```

启动开发服务：

```powershell
npm run dev
```

前端默认地址：

```text
http://localhost:3000
```

### 3. 前端构建和测试

运行前端测试：

```powershell
npm test
```

构建生产版本：

```powershell
npm run build
```

## PostgreSQL 数据库配置方法

项目使用 PostgreSQL。数据库配置通过环境变量控制，不要把真实密码写死到代码中。

### 1. 创建环境变量文件

在项目根目录复制 `.env.example`：

```powershell
cd E:\daima_code\大项目\blog
copy .env.example .env
```

然后根据本机环境修改 `.env`。

核心数据库配置如下：

```env
POSTGRES_DB=ai_knowledge_blog
POSTGRES_USER=blog
POSTGRES_PASSWORD=change-me
DB_HOST=postgres
DB_PORT=5432
```

如果你不用 Docker，而是连接本机 PostgreSQL，需要把后端运行环境中的数据库地址改成本机地址：

```env
DB_HOST=localhost
DB_PORT=5432
POSTGRES_DB=ai_knowledge_blog
POSTGRES_USER=blog
POSTGRES_PASSWORD=你的数据库密码
```

### 2. 初始化数据库

数据库 SQL 文件在：

```text
docs/sql/001_schema.sql
docs/sql/002_seed.sql
```

如果使用 Docker Compose，PostgreSQL 容器首次启动时会自动执行 `docs/sql` 下的初始化脚本。

如果手动连接本机 PostgreSQL，可以按顺序执行：

```sql
CREATE DATABASE ai_knowledge_blog;
```

然后在项目根目录执行：

```powershell
psql -U blog -d ai_knowledge_blog -f docs/sql/001_schema.sql
psql -U blog -d ai_knowledge_blog -f docs/sql/002_seed.sql
```

如果使用超级用户创建业务账号，可以参考：

```sql
CREATE USER blog WITH PASSWORD '你的数据库密码';
CREATE DATABASE ai_knowledge_blog OWNER blog;
GRANT ALL PRIVILEGES ON DATABASE ai_knowledge_blog TO blog;
```

### 3. 后端数据库连接配置

后端读取 `backend/src/main/resources/application.yml` 中的配置：

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${POSTGRES_DB:ai_knowledge_blog}
    username: ${POSTGRES_USER:blog}
    password: ${POSTGRES_PASSWORD:change-me}
```

实际值优先来自环境变量或 `.env`。

## Redis 配置

Redis 用于后续登录状态、Refresh Token、缓存、限流和推荐任务状态。

`.env` 中的配置：

```env
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=change-redis-me
```

如果连接本机 Redis：

```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=你的Redis密码
```

##   配置

MinIO 用于后续图片、附件和 Markdown 导入资源存储。

`.env` 中的配置：

```env
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=change-minio-password
MINIO_BUCKET=blog-assets
MINIO_ENDPOINT=http://minio:9000
MINIO_PUBLIC_ENDPOINT=http://localhost:9000
```

本地开发时 MinIO API 默认访问地址：

```text
http://localhost:9000
```

MinIO 控制台默认只绑定本机：

```text
http://localhost:9001
```

生产环境不要把 MinIO 控制台直接暴露到公网。

## Docker 运行方法

### 1. 准备环境变量

在项目根目录执行：

```powershell
cd E:\daima_code\大项目\blog
copy .env.example .env
```

修改 `.env` 中的密码和密钥，至少需要调整：

```env
JWT_SECRET=replace-with-at-least-32-random-characters
POSTGRES_PASSWORD=change-me
REDIS_PASSWORD=change-redis-me
MINIO_ROOT_PASSWORD=change-minio-password
```

### 2. 校验 Docker Compose 配置

```powershell
docker compose --env-file .env config
```

如果还没有 `.env`，也可以用示例文件校验：

```powershell
docker compose --env-file .env.example config
```

### 3. 构建并启动全部服务

```powershell
docker compose --env-file .env up -d --build
```

启动的服务包括：

- `frontend`：Nuxt SSR 前端服务
- `backend`：Spring Boot 后端服务
- `postgres`：PostgreSQL 数据库
- `redis`：Redis
- `minio`：对象存储
- `nginx`：统一入口和反向代理

### 4. 查看服务状态

```powershell
docker compose ps
```

查看日志：

```powershell
docker compose logs -f
```

只查看后端日志：

```powershell
docker compose logs -f backend
```

只查看数据库日志：

```powershell
docker compose logs -f postgres
```

### 5. 访问服务

Nginx 统一入口：

```text
http://localhost:8088
```

后端接口会通过 Nginx 转发：

```text
http://localhost:8088/api/public/health
```

前端页面：

```text
http://localhost:8088
```

MinIO API：

```text
http://localhost:9000
```

MinIO 控制台：

```text
http://localhost:9001
```

### 6. 停止服务

```powershell
docker compose down
```

如果需要同时删除数据卷：

```powershell
docker compose down -v
```

注意：`-v` 会删除 PostgreSQL、Redis、MinIO 的本地数据卷，谨慎使用。

## 常用开发命令

后端测试：

```powershell
cd backend
mvn test
```

前端测试：

```powershell
cd frontend
npm test
```

前端构建：

```powershell
cd frontend
npm run build
```

Docker 配置校验：

```powershell
docker compose --env-file .env.example config
```

## 当前阶段说明

当前是第一阶段初始化版本，已经包含：

- 后端健康检查
- 后端统一响应结构
- 后端全局异常处理
- Knife4j / OpenAPI 配置
- 前端基础页面
- 浅色 / 深色主题变量
- Docker Compose 基础编排
- Nginx 反向代理
- PostgreSQL 建表脚本
- 初始化分类、标签、系列示例数据

后续阶段会继续实现：

- 管理员登录和 JWT
- 文章 CRUD
- Markdown / Tiptap 编辑器
- 图片和附件上传
- Markdown 导入
- 智能延伸阅读
- 学习规划
- RSS、Sitemap、SEO 和缓存

## 安全说明

- 不要提交真实密码、Token、API Key。
- `.env` 应只保存在本地或部署环境。
- PostgreSQL 和 Redis 默认只在 Docker 网络内部访问。
- MinIO 控制台生产环境不要直接暴露公网。
- 管理员密码必须使用 BCrypt 哈希保存，不能保存明文密码。
- 外部 AI 和搜索服务必须通过环境变量配置 API Key。

