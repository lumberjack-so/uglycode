# uglycode

A complete, copy-pasteable Claude Code configuration template for fully autonomous production development.

Based on the patterns used by Boris Cherny (Claude Code's creator at Anthropic) to land 259 PRs — 497 commits, 40k lines added, 38k removed — in 30 days.

## What's included

This template sets up a full autonomous Claude Code environment for a mixed-stack project (Next.js 14 + TypeScript, Python/FastAPI, Node.js services):

### Configuration files
| File | Purpose |
|------|---------|
| `CLAUDE.md` | Semantic anchor — project conventions, commands, code style, critical dev rules |
| `.claude/settings.json` | Master config — permissions, hooks, plugin enablement |
| `.mcp.json` | MCP server configuration (GitHub, Sentry, dbhub, Context7) |
| `.gitignore` | Ignores local settings and Ralph Wiggum state files |

### Hooks (`.claude/hooks/`)
| Hook | Trigger | Purpose |
|------|---------|---------|
| `block-dangerous-git.sh` | PreToolUse (Bash) | Blocks force push, reset --hard, destructive rm -rf |
| `protect-files.sh` | PreToolUse (Edit/Write) | Guards .env, lockfiles, migrations, docker-compose.prod.yml |
| `auto-format.sh` | PostToolUse (Edit/Write) | Runs Prettier on TS/JS, Black + isort on Python |
| `auto-test.sh` | PostToolUse (Edit/Write) | Runs matching test file after code edits |
| `stop-validation.sh` | Stop | Blocks Claude from stopping if tests are failing |

### Commands (`.claude/commands/`)
| Command | Description |
|---------|-------------|
| `/todo-all` | Autonomous task loop — reads `.llm/todo.md`, launches subagents per task |
| `/commit` | Conventional commit workflow with emoji prefixes |
| `/deploy` | VPS deployment with 6 pre-flight checks |

### Agents, Skills & Rules
| File | Description |
|------|-------------|
| `.claude/agents/do-todo.md` | Sonnet-based single-task executor subagent |
| `.claude/skills/tdd-integration/SKILL.md` | TDD Red-Green-Refactor cycle enforcement |
| `.claude/rules/typescript.md` | Path-scoped TypeScript rules (src/app directories) |
| `.claude/rules/python.md` | Path-scoped Python rules (api/services directories) |

### Task management
| File | Description |
|------|-------------|
| `.llm/todo.md` | Sprint task list template for autonomous runs |

### CI/CD
| File | Description |
|------|-------------|
| `.github/workflows/claude-review.yml` | GitHub Actions PR review with claude-code-action |

## Quick start

```bash
# 1. Clone the template
git clone https://github.com/lumberjack-so/uglycode.git my-project
cd my-project

# 2. Edit CLAUDE.md with your actual project details
vim CLAUDE.md

# 3. Edit .llm/todo.md with your sprint tasks
vim .llm/todo.md

# 4. Start Claude Code
claude
```

## Post-setup steps (inside Claude Code)

After cloning and customizing, run these commands inside a Claude Code session:

1. **Install the Ralph Wiggum plugin** for hours-long autonomous sessions:
   ```
   /plugin install ralph-wiggum@claude-plugins-official
   ```

2. **Connect GitHub** for CI/CD integration:
   ```
   /install-github-app
   ```

3. **Start an autonomous run** with the Ralph Wiggum loop:
   ```
   /ralph-wiggum:ralph-loop "Go through .llm/todo.md step by step. For each task: write tests first, implement minimally, run tests, commit with conventional message, check off the task. Output <promise>DONE</promise> when complete." --max-iterations 30 --completion-promise "DONE"
   ```

## Directory structure

```
project-root/
├── CLAUDE.md
├── README.md
├── .claude/
│   ├── settings.json
│   ├── hooks/
│   │   ├── block-dangerous-git.sh
│   │   ├── protect-files.sh
│   │   ├── auto-format.sh
│   │   ├── auto-test.sh
│   │   └── stop-validation.sh
│   ├── commands/
│   │   ├── commit.md
│   │   ├── deploy.md
│   │   └── todo-all.md
│   ├── agents/
│   │   └── do-todo.md
│   ├── skills/
│   │   └── tdd-integration/
│   │       └── SKILL.md
│   └── rules/
│       ├── typescript.md
│       └── python.md
├── .mcp.json
├── .llm/
│   └── todo.md
├── .github/
│   └── workflows/
│       └── claude-review.yml
└── .gitignore
```

## Customization

- **Stack-specific**: Edit `CLAUDE.md` commands section and `.claude/rules/` to match your actual stack
- **Permissions**: Adjust `allow`/`deny` lists in `.claude/settings.json` for your workflow
- **MCP servers**: Edit `.mcp.json` to enable/disable servers (each consumes context tokens)
- **Hooks**: Modify hook scripts in `.claude/hooks/` to match your tooling (e.g., swap Prettier for Biome)

## License

MIT
