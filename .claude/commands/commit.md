# Conventional Commit Workflow

1. Run `git diff --cached --stat`
2. If nothing staged: `git add -A`
3. Analyze changes and determine commit type:
   - `feat:` — new feature
   - `fix:` — bug fix
   - `test:` — adding/updating tests
   - `docs:` — documentation only
   - `chore:` — maintenance, config changes
   - `refactor:` — code restructure, no behavior change
   - `style:` — formatting, whitespace
   - `perf:` — performance improvement
4. Write a concise commit message: `type: description`
5. Run `git commit -m "type: description"`
6. Output the commit hash and message
