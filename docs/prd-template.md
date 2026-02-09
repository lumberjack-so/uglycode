# Product Requirements Document

## Product Name
[Your product name]

## One-Line Description
[What it does in one sentence]

## Problem
[What problem does this solve? Who has this problem?]

## Solution
[How does this product solve the problem?]

## Stack
[Be specific — the factory uses this to generate correct tasks]
- **Backend:** [e.g., Python 3.12, FastAPI, PostgreSQL, Redis]
- **Frontend:** [e.g., Next.js 14, TypeScript, Tailwind CSS]
- **Infrastructure:** [e.g., Docker Compose, Nginx, GitHub Actions]
- **Key Libraries:** [e.g., Graphiti, Milvus, Airbyte, etc.]

## Core Features (MVP)
[List the features in priority order. The factory will turn each into sprint tasks.]

### Feature 1: [Name]
[Description. What the user does. What happens. What the expected output is.]

### Feature 2: [Name]
[Description.]

### Feature 3: [Name]
[Description.]

## Data Model
[Describe the main entities and their relationships. Be specific about field names and types.]

## API Endpoints
[List the key endpoints. The factory generates tasks from these.]

| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check |
| POST | /api/... | ... |

## Non-Functional Requirements
- **Auth:** [e.g., JWT, OAuth2, none for MVP]
- **Performance:** [e.g., API response < 500ms]
- **Deployment:** [e.g., single VPS, Docker Compose]
- **Testing:** [e.g., >80% coverage, integration tests for all endpoints]

## Out of Scope (for now)
[What this product does NOT do in v1. Important — prevents the factory from overbuilding.]
