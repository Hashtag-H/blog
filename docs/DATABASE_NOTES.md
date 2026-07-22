# Database Notes

The schema uses foreign keys for core ownership relations:

- `article.category_id -> category.id`
- `article.series_id -> series.id`
- `article_tag.article_id -> article.id`
- `article_tag.tag_id -> tag.id`
- `external_recommendation.article_id -> article.id`

Articles and admin users include a `deleted` flag for logical deletion. Category, tag, and series currently use hard deletion only after dependency checks; later stages may add logical deletion if needed.

`created_at` and `updated_at` are initialized by PostgreSQL defaults in the initial schema. MyBatis-Plus auto-fill can be added in the backend common configuration when entities are introduced, and update timestamps should be maintained by application code or a PostgreSQL trigger in later stages.
