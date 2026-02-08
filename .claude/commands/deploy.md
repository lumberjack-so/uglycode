---
description: "Deploy to VPS with pre-flight checks"
allowed-tools: ["Bash"]
---
# Deployment Workflow

## Pre-flight checks (ALL must pass)
1. `npm run build` — production build succeeds
2. `npm test -- --run` — all tests pass
3. `pytest -x -q` — all Python tests pass
4. `npx tsc --noEmit` — no TypeScript errors
5. `npm run lint` — no lint errors
6. `git status` — working directory clean (all changes committed)

## Deploy sequence
If pre-flight passes:
1. `git push origin $(git branch --show-current)`
2. `ssh deploy@$VPS_HOST 'cd /app && git pull && docker compose up -d --build'`

If any pre-flight check fails, stop and report the failure. Do not deploy.
