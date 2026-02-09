# Project Configuration

## Identity
- Project: uglycode-factory
- Stack: Next.js 14 + TypeScript, Python/FastAPI, Docker Compose
- Repo: github.com/lumberjack-so/uglycode-factory

## Commands
```bash
# Dev
npm run dev                    # Start Next.js dev server
cd api && uvicorn app.main:app --reload  # Start API server

# Test
npm test                       # Frontend tests
cd api && pytest -x -q         # Backend tests
npm run typecheck              # TypeScript type checking

# Lint / Format
npx prettier --write .         # Format JS/TS
cd api && black . && isort .   # Format Python

# Build
npm run build                  # Production build
docker compose -f infra/docker-compose.yml up -d  # Start infrastructure
```

## Code Style
- TypeScript: strict mode, no `any`, prefer `interface` over `type`, `satisfies` over `as`
- Python: Black formatter, isort, type hints on all functions, Pydantic v2
- Tests: Arrange-Act-Assert pattern, descriptive names
- Commits: conventional commits (feat:, fix:, test:, docs:, chore:)
- Imports: absolute paths, group by stdlib > external > internal

## File Organization
- `app/` — Next.js App Router frontend
- `api/` — FastAPI backend
- `services/` — Shared backend services
- `tests/` — Test files mirror source structure
- `infra/` — Docker, deployment configs
- `docs/` — Documentation

## Critical Rules
- NEVER commit directly to main
- NEVER modify .env files
- NEVER delete migration files
- NEVER use `git push --force`
- ALWAYS run tests before committing
- ALWAYS use conventional commit messages

---

## Factory Rules

### Filesystem Memory (READ AND UPDATE THESE)
- `.llm/state.md` — Update after EVERY completed task
- `.llm/decisions.md` — Append on any architectural choice (D-NNN format)
- `.llm/blockers.md` — Append when blocked (B-NNN format)
- `.llm/exemplars/` — Check before building; save reusable patterns

### Context Management
- START of session: read `.llm/stage-context.md` (if exists), then `state.md`, then `todo.md`
- END of session: update `state.md` with final status. Keep under 50 lines.

### Quality Gates (MUST pass before marking ANY task complete)
- All existing tests still pass
- No type errors
- New code has at least one test
- `.llm/state.md` updated

### Anti-Drift Rules
- Do NOT refactor code outside current task
- Do NOT add unspecified dependencies
- Do NOT restructure directories unless task says to
- Do NOT modify `.scenarios/`, `.validation/`, or `.factory/`
- If blocked, log to `.llm/blockers.md` and move to next task
- If working on something not in `.llm/todo.md`, STOP and re-read

### Gene Transfusion
- Before creating new endpoints/components/tests, check `.llm/exemplars/`
- Save clean reusable patterns as new exemplars

### Compaction Summary
When context runs low, write a 3-line summary to `.llm/state.md`: what was done, what's next, what's blocking.
