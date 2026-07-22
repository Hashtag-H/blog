# Implementation Plan

## Environment Check

- Java 17: available.
- Maven 3.9.1: available.
- Node 20.19.5: available.
- npm 10.8.2: available.
- Docker 29.4.3: available, with a local Docker config permission warning.
- Docker Compose v5.1.3: available, with the same local Docker config warning.

## Stage 1: Project Initialization

Create the runnable monorepo foundation:

- `frontend/`: Nuxt 4 app, Tailwind design tokens, Pinia store, initial public pages.
- `backend/`: Spring Boot app, common API response, health endpoint, OpenAPI setup.
- `deploy/`: Nginx reverse proxy.
- `docs/`: SQL schema, seed data, and architecture notes.
- Root: Docker Compose, `.env.example`, README.

Verification:

- Run backend tests with Maven.
- Run frontend build after installing dependencies.
- Validate Docker Compose configuration.

## Later Stages

1. Login, JWT, route protection, base UI shell.
2. Article/category/tag/series CRUD and public article views.
3. Editor, Markdown import, file upload, MinIO integration.
4. Intelligent extended reading adapters and review workflow.
5. Learning plan CRUD and AI-assisted generation.
6. SEO, RSS, sitemap, caching, responsive polish, production deployment docs.

