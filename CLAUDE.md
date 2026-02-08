# Project: uglycode
Mixed stack: Next.js 14 (App Router) + TypeScript, Python/FastAPI, Node.js services.
Deployed to self-hosted VPS via SSH. Monorepo structure.

## Commands
- `npm run dev` — Next.js dev server (port 3000)
- `npm run build` — Production build
- `npm run test` — Vitest test suite
- `npm run lint` — ESLint + Prettier check
- `uvicorn app.main:app --reload` — FastAPI dev server
- `pytest` — Python test suite
- `docker compose up -d` — Local services

## Code style
- TypeScript: strict mode, no `any`, named exports only, Zod for validation
- Python: type hints required, Pydantic models, async where possible
- CSS: Tailwind utility classes only, no custom CSS files
- Prefer composition over inheritance everywhere

## CRITICAL development rules
- IMPORTANT: Make minimal, surgical changes. Do not refactor unless explicitly asked.
- Before creating new files, check if existing files can be modified instead.
- Do not add abstraction layers unless explicitly requested.
- Do not rename existing functions, variables, or files unless asked.
- Prefer modifying 1-3 existing files over creating new architecture.
- Find and follow 3 similar patterns already in this codebase before implementing.
- If a task seems unreasonable or infeasible, say so rather than working around it.
- NEVER commit .env files or secrets. Check .gitignore before creating files.

## Testing
- Write tests first. Run tests after every change. Do not mark tasks complete with failing tests.
- Test command for TypeScript: `npm test -- --run`
- Test command for Python: `pytest -x -q`
- Integration tests: `npm run test:e2e`

## Git workflow
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- One logical change per commit. Never mix unrelated changes.
- Never force push. Never push directly to main. Always use feature branches.
- Branch naming: `feat/description`, `fix/description`, `chore/description`

## Architecture (brief)
- `/app` — Next.js App Router pages and layouts
- `/src/components` — React components (co-located tests as `*.test.tsx`)
- `/src/lib` — Shared utilities
- `/api` — FastAPI application
- `/services` — Node.js microservices
- `/deploy` — Deployment scripts and configs
- For auth flow details, see docs/auth.md
- For API conventions, see docs/api-guide.md

## Summary instructions
When compacting, preserve: full list of modified files, test commands, current task progress, and any blocking issues.
