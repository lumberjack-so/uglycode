# uglycode-factory

A copy-pasteable Claude Code configuration that turns a PRD into working software.

No human writes code. No human reviews code. No human writes tasks. You write the PRD, the factory does everything else.

Based on patterns from Boris Cherny (Claude Code at Anthropic) and StrongDM's Software Factory.

## Quick start

```bash
# 1. Clone into your project
git clone https://github.com/lumberjack-so/uglycode-factory.git my-project
cd my-project

# 2. Edit CLAUDE.md — replace stack and project name
vim CLAUDE.md

# 3. Write your PRD
vim docs/prd.md

# 4. Start Claude Code and install Ralph Wiggum (first time only)
claude
/plugin marketplace add anthropics/claude-code
/plugin install ralph-wiggum@claude-plugins-official
exit

# NOTE: If the official plugin fails (known CVE-2025-54795 bug),
# use the working fork instead:
#   git clone https://github.com/dial481/ralph.git ~/claude-plugins/ralph
#   # In Claude Code:
#   /plugin marketplace add ~/claude-plugins
#   /plugin install ralph@local

# 5. Run the factory
.factory/run.sh docs/prd.md
```

That's it. The factory:
1. Breaks your PRD into sprints with task lists
2. Generates scenario holdout sets per sprint
3. Updates CLAUDE.md with sprint-specific context
4. Runs Claude Code autonomously via Ralph Wiggum
5. Validates output against scenarios using a separate LLM judge
6. Scores satisfaction 0-10 and decides: continue, retry, or stop
7. Transitions between sprints with pyramid summaries
8. Creates PRs for each completed sprint

## How it works

```
                        +-----------+
                        |  YOU      |
                        | write PRD |
                        +-----+-----+
                              |
                              v
                    +-----------------+
                    | generate-sprints | PRD -> sprint task lists
                    +--------+--------+
                             |
              +--------------+--------------+
              v              v              v
         sprint-0.md    sprint-1.md    sprint-N.md
              |
              v
     +------------------+
     |generate-scenarios | PRD + tasks -> holdout scenarios
     +--------+---------+
              |
              v
    +-------------------+
    |  orchestrate.sh    | loads tasks -> launches agent -> validates
    +--------+----------+
             |
     +-------+--------+
     v       v        v
  +------+ +------+ +------+
  |Stage | |Stage | |Stage |  15 iterations each, fresh context
  |  1   | |  2   | |  3   |
  +--+---+ +--+---+ +--+---+
     |        |        |
     v        v        v
  +----------------------------+
  |  LLM Judge (separate       |  evaluates against scenarios
  |  Claude session)           |  scores satisfaction 0-10
  +-----------+----------------+
              |
       >=8: continue
      5-7: caution
       <5: stop
              |
              v
  +-------------------+
  |  next-sprint.sh    |  PR, pyramid summary, reset, next sprint
  +-------------------+
```

## What you interact with

During a factory run, you do three things:

1. **Paste the Ralph Wiggum command** the orchestrator prints for you
2. **Press ENTER** when a stage finishes
3. **Enter the satisfaction score** (0-10) from the LLM judge

That's the entire human interaction per stage.

## Stack (default configuration)

- **Frontend:** Next.js 14 + TypeScript (App Router)
- **Backend:** Python/FastAPI
- **Infrastructure:** Docker Compose
- **MCP Servers:** GitHub, Context7, dbhub

## Enhanced features (vs base template)

- **jq-based hooks** — Reliable JSON parsing in all hook scripts
- **hookSpecificOutput format** — Proper deny/allow responses with reasons
- **Timeout-configured hooks** — 5s for PreToolUse, 30s for formatting, 120s for tests/stop
- **3 new subagents** — code-reviewer, precommit-runner, git-commit-handler
- **Path-scoped rules** — TypeScript, Python, and deployment rules load only for matching files
- **3 MCP servers** — GitHub, Context7 (docs), dbhub (database)
- **Expanded permissions** — Read(**), WebFetch, WebSearch, TodoRead/Write, Task, gh pr
- **Expanded deny rules** — sudo, chmod 777, curl|bash, secrets, lockfiles

## If you need to resume

```bash
# Resume from sprint 3
.factory/run.sh docs/prd.md 3
```

## Directory structure

```
project-root/
├── CLAUDE.md                          # Project rules + factory rules
├── docs/
│   └── prd-template.md               # PRD template
│
├── .claude/                           # Claude Code configuration
│   ├── settings.json                  # Permissions, hooks, plugins
│   ├── hooks/                         # 6 hook scripts (jq-enhanced)
│   ├── commands/                      # 3 slash commands
│   ├── agents/                        # 4 subagents (1 reused + 3 new)
│   ├── skills/tdd-integration/        # TDD enforcement
│   └── rules/                         # 3 path-scoped rule files
│
├── .scenarios/                        # Holdout validation (agent CANNOT access)
├── .validation/                       # Validation harness + score history
├── .factory/                          # Factory orchestration (6 scripts)
├── .llm/                             # Agent memory + tasks
├── .mcp.json                          # MCP server connections (GitHub, Context7, dbhub)
├── .github/workflows/                 # CI/CD (Claude Code PR review)
└── .gitignore
```

## Configuration

| File | What to edit | When |
|------|-------------|------|
| `CLAUDE.md` | Replace stack, project name, commands | Once, at project start |
| `.claude/settings.json` | Add project-specific paths to allow list | When agent asks for permissions |
| `.claude/rules/*.md` | Match your actual languages and conventions | Once, at project start |
| `.mcp.json` | Add GitHub token, database URL | Once, at project start |

## Key principles

**PRD is the only input.** Everything else is generated.

**Code is opaque.** Tests, scenarios, and smoke checks tell you if it works.

**Validation is separate from implementation.** The coding agent can't see `.scenarios/`.

**Filesystem is memory.** `state.md`, `decisions.md`, `blockers.md` persist across sessions.

**Drift is instruction failure.** When the agent builds wrong, fix the PRD or CLAUDE.md.

**Satisfaction replaces pass/fail.** Scores 0-10 give gradient signal, not binary.

## Credits

- [Boris Cherny](https://github.com/anthropics/claude-code) — Claude Code, uglycode patterns
- [StrongDM Software Factory](https://factory.strongdm.ai/) — Scenarios, satisfaction scoring, filesystem-as-memory, pyramid summaries
- [Ralph Wiggum Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) — Official autonomous loop
- [dial481/ralph](https://github.com/dial481/ralph) — Working fork if official plugin hits CVE-2025-54795
- [Geoffrey Huntley](https://ghuntley.com) — Original Ralph Wiggum technique

## License

MIT
