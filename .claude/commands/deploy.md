# Deploy with Pre-Flight Checks

1. Verify NOT on main branch
2. Run tests: `npm test` and `cd api && pytest -x -q`
3. Type check: `npx tsc --noEmit` (if TypeScript)
4. Build check: `npm run build`
5. Lint check: `npx prettier --check .`
6. Git status: working tree must be clean

If ALL checks pass:
- Push branch: `git push origin HEAD`
- Create PR: `gh pr create --title "type: description" --body "..."`
- Output the PR URL

If ANY check fails:
- Report which check failed and why
- Do NOT push or create PR
