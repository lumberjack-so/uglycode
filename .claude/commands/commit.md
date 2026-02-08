---
description: "Create conventional commits with proper formatting"
allowed-tools: ["Bash(git add *)", "Bash(git status)", "Bash(git commit *)", "Bash(git diff *)", "Bash(git log *)"]
---
# Commit Workflow

1. Run `git status` and `git diff --cached` to see staged changes
2. If nothing staged, ask which files to stage
3. Analyze the changes and determine the commit type:
   - ✨ `feat:` — new feature
   - 🐛 `fix:` — bug fix
   - 📝 `docs:` — documentation
   - ♻️ `refactor:` — code restructuring
   - ✅ `test:` — adding/updating tests
   - 🔧 `chore:` — maintenance
4. Write a commit message: `<emoji> <type>: <imperative description>`
5. First line under 72 characters
6. Add body with bullet points if the change is non-trivial
7. Commit with `git commit -m "<message>"`

Example: `✨ feat: add JWT token refresh endpoint`
