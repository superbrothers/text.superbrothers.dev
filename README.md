# text.superbrothers.dev

Personal blog built with [Hugo](https://gohugo.io/).

## Development Commands

- `make serve-dev`: Start local Hugo server with drafts enabled (`http://localhost:8080`)
- `make build`: Build the site for production into `public/`

## Publishing Workflow

When drafting, updating, or publishing a post, adhere to the following workflow:

### 1. Post Creation & Frontmatter

- **File Path**: `content/YYMMDD-<slug>.md` (e.g., `content/260925-my-post.md`)
- **Required Frontmatter**:
  ```yaml
  ---
  title: "Title"
  date: 2026-09-25T13:00:00+09:00
  draft: false
  images:
  - /ogp/YYMMDD-<slug>.png
  tags:
  - example
  ---
  ```

### 2. Pre-Publish Processing

Before committing and pushing changes, you must execute these steps in order:

1. **Optimize Images** (required if images were added to `content/`):
   ```bash
   make optimize-images
   ```
2. **Generate OGP Image**:
   ```bash
   make generate-ogp-images
   ```
   - Generates `static/ogp/YYMMDD-<slug>.png`.
3. **Verify Build**:
   ```bash
   make build
   ```

### 3. Commit & Push

- Verify `git status` includes:
  - The markdown file in `content/`
  - The generated OGP image in `static/ogp/`
  - Any optimized images (`.webp`)
- Commit all related assets and push.
