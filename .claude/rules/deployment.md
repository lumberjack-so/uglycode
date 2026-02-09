---
paths:
  - "deploy/**"
  - "infra/**"
  - "Dockerfile*"
  - "docker-compose*"
---

# Deployment Rules

- Dockerfiles: multi-stage builds, non-root user, .dockerignore present
- Base images: use specific tags (not `latest`), prefer slim/alpine variants
- docker-compose: use named volumes, explicit networks, health checks on all services
- Environment: use .env.example for documentation, never commit actual .env files
- Ports: map to non-privileged ports (>1024) in dev
- Secrets: use environment variables or Docker secrets, never hardcode
- Health checks: every service must expose a /health endpoint
- Logging: structured JSON logs, no print statements in production
- Restart policy: `unless-stopped` for dev, `on-failure` for production
