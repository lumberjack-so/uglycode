# uglycode-factory

A PRD-to-software pipeline for Claude Code. Write a product requirements document, run one command, and the factory autonomously generates sprint plans, writes code, validates against holdout test scenarios, scores quality, and transitions between sprints — no human in the loop.

## Quick Start

```bash
# 1. Clone the template into your project
git clone https://github.com/lumberjack-so/uglycode-factory.git my-project
cd my-project

# 2. Edit CLAUDE.md — set your project name, stack, and commands
vim CLAUDE.md

# 3. Write your PRD (template included)
cp docs/prd-template.md docs/prd.md
vim docs/prd.md

# 4. Install the Ralph Wiggum plugin (first time only)
claude
/install-plugin ralph-wiggum@claude-plugins-official
exit

# 5. Run the factory
.factory/run.sh docs/prd.md
```

The factory takes over from here. It breaks your PRD into sprints, generates task lists, launches Claude Code to implement each sprint, validates the output against scenarios it generates (that the coding agent never sees), scores satisfaction, and moves to the next sprint. You get PRs, logs, and a satisfaction history when it's done.

### Manual Mode

If you prefer to control each stage interactively — pasting commands and entering scores yourself:

```bash
.factory/run.sh docs/prd.md --manual
```

### Resuming

If the factory stops (low satisfaction score, error, or interruption), resume from any sprint:

```bash
.factory/run.sh docs/prd.md 3           # Resume from sprint 3
.factory/run.sh docs/prd.md 3 --manual  # Resume in manual mode
```

## How It Works

The factory is a pipeline of six bash scripts that coordinate Claude Code sessions. Each sprint goes through three phases: **plan**, **build**, and **evaluate**.

```
 YOU
  |
  |  write a PRD
  v
 .factory/run.sh
  |
  |  1. generate-sprints.sh    PRD --> sprint-0.md ... sprint-N.md
  |  2. generate-scenarios.sh  PRD + tasks --> holdout test scenarios
  |
  |  For each sprint:
  |
  |    orchestrate.sh (up to 3 stages per sprint)
  |    |
  |    |  Write context handoff --> .llm/stage-context.md
  |    |
  |    |  Launch coding agent (claude -p with Ralph Wiggum)
  |    |  |
  |    |  |  Reads .llm/todo.md, works through tasks top to bottom
  |    |  |  Writes tests first, implements, commits, updates state
  |    |  |  Stops at HARD STOP checkpoints for validation
  |    |  |  Logs output --> .validation/stage-{sprint}-{stage}.log
  |    |  |
  |    |  Run validation harness --> collect evidence
  |    |  |
  |    |  Launch judge (separate claude -p session)
  |    |  |
  |    |  |  Evaluates evidence against holdout scenarios
  |    |  |  Returns satisfaction score 0-10
  |    |  |  Logs output --> .validation/judge-{sprint}-{stage}.json
  |    |  |
  |    |  Score >= 8: PASS, continue
  |    |  Score 5-7:  continue with caution
  |    |  Score < 5:  STOP for review
  |    |
  |    next-sprint.sh
  |    |  Create PR for completed sprint
  |    |  Write pyramid summary
  |    |  Reset agent state
  |    |  Load next sprint's tasks
  |
  v
 FACTORY COMPLETE
  |
  PRs created, satisfaction history logged, code shipped
```

### Sprint Generation

`generate-sprints.sh` sends your PRD to Claude with strict formatting rules. It produces 5-12 sprints, each with 5-15 tasks. Sprint 0 is always scaffold (project structure, infrastructure, stubs). The last sprint is always hardening (error handling, edge cases, production config). Every sprint includes HARD STOP checkpoints every 4-6 tasks where the agent pauses for validation.

Each task follows a strict format:

```
- [ ] 3. Create health endpoint — Artifact: `api/routes/health.py`. Constraint: return {"status": "ok"} only. Verify: `curl localhost:8000/health` returns 200.
```

### The Coding Agent

Each stage launches a fresh Claude Code session using Ralph Wiggum's autonomous loop (`ralph-loop`). The agent:

1. Reads `.llm/stage-context.md` for handoff context from the previous stage
2. Reads `.llm/todo.md` for its task list
3. For each task: reads existing code, checks `.llm/exemplars/` for patterns, writes a failing test, implements minimally to pass, runs the full test suite, commits with a conventional message, marks the task complete
4. Stops at HARD STOP tasks and reports status
5. Updates `.llm/state.md` after every completed task

The agent runs with `--dangerously-skip-permissions` so it can execute without confirmation dialogs. It gets up to 15 iterations per stage, and up to 3 stages per sprint.

### Validation and Judging

The coding agent cannot see `.scenarios/` or `.validation/` (enforced by permission deny rules in `settings.json`). This separation is critical — the scenarios are a holdout set.

After each stage, `validate.sh` collects evidence:

- Directory structure
- Recent git commits and diffs
- Test results (pytest + npm test)
- API health check response
- Agent state and blockers

This evidence, along with the holdout scenarios, is assembled into a judge prompt. A separate Claude session evaluates the evidence and returns a JSON verdict:

```json
{
  "scenarios": [{ "id": "S-SMOKE-01", "status": "PASS", "reason": "..." }],
  "satisfaction": 8,
  "total_pass": 5,
  "total_fail": 1,
  "total_unknown": 0,
  "blockers": [],
  "recommendations": []
}
```

The satisfaction score (0-10) determines what happens next. Scores are logged to `.validation/satisfaction-log.jsonl` for the full history.

### Sprint Transitions

When a sprint completes, `next-sprint.sh`:

1. Creates a git branch and PR for the completed sprint
2. Checks out `main` and writes a pyramid summary (`.llm/sprint-N-summary.md`)
3. Resets agent state files for the next sprint
4. Loads the next sprint's tasks and CLAUDE.md additions

## Architecture

### Filesystem as Memory

The agent maintains state across sessions through files, not conversation history:

| File                    | Purpose                                           | Updated                    |
| ----------------------- | ------------------------------------------------- | -------------------------- |
| `.llm/state.md`         | Current task, next task, blockers, modified files | After every task           |
| `.llm/todo.md`          | Sprint task list with checkboxes                  | As tasks complete          |
| `.llm/decisions.md`     | Architectural decisions (D-NNN format)            | On any design choice       |
| `.llm/blockers.md`      | Issues the agent can't resolve (B-NNN format)     | When blocked               |
| `.llm/exemplars/`       | Reusable code patterns                            | When clean patterns emerge |
| `.llm/stage-context.md` | Handoff between stages                            | By the orchestrator        |

### Separation of Concerns

```
.factory/          Orchestration scripts (6 files)
                   The pipeline controller. Coordinates everything.

.llm/              Agent memory and task state
                   The only mutable state the coding agent touches.

.scenarios/        Holdout test scenarios
                   Generated per sprint. The coding agent CANNOT access these.

.validation/       Validation harness, judge prompts, logs
                   Evidence collection and scoring. Agent CANNOT access.

.claude/           Claude Code configuration
                   Hooks, agents, commands, rules, skills, permissions.

.github/workflows/ CI/CD
                   Claude Code PR review workflow.
```

### Hooks

Six hook scripts enforce discipline during coding:

| Hook                     | Trigger                  | What it does                                                                   |
| ------------------------ | ------------------------ | ------------------------------------------------------------------------------ |
| `block-dangerous-git.sh` | PreToolUse (Bash)        | Blocks force push, reset --hard, rm -rf, and other destructive commands        |
| `protect-files.sh`       | PreToolUse (Edit/Write)  | Prevents modification of .env, .scenarios/, .validation/, .factory/, CLAUDE.md |
| `auto-format.sh`         | PostToolUse (Edit/Write) | Runs Prettier (JS/TS) and Black+isort (Python) after file changes              |
| `auto-test.sh`           | PostToolUse (Edit/Write) | Runs relevant test suite after file changes                                    |
| `stop-validation.sh`     | Stop                     | Blocks the agent from stopping if tests are failing                            |
| `drift-check.sh`         | Stop                     | Warns if unchecked tasks remain in todo.md                                     |

### Subagents

Four specialized agents handle specific workflows:

| Agent                   | Purpose                                                  |
| ----------------------- | -------------------------------------------------------- |
| `do-todo.md`            | Focused single-task executor using TDD                   |
| `code-reviewer.md`      | Reviews changed files against project rules              |
| `precommit-runner.md`   | Runs tests, type checks, linting before commits          |
| `git-commit-handler.md` | Analyzes staged changes and creates conventional commits |

### Rules

Path-scoped rules load only when working on matching files:

| Rule            | Applies to                                   |
| --------------- | -------------------------------------------- |
| `typescript.md` | `*.ts`, `*.tsx` files                        |
| `python.md`     | `*.py` files                                 |
| `deployment.md` | `infra/**`, `docker-compose*`, `Dockerfile*` |

### Permissions

The `settings.json` configures what the coding agent can and cannot do:

**Allowed:** Read all files, write/edit project code (`api/`, `app/`, `services/`, `tests/`, `infra/`, `docs/`), git operations (add, commit, checkout, branch, push to origin), npm/pytest/docker commands, web search/fetch, task management.

**Denied:** Force push, reset --hard, rm -rf, sudo, curl|bash, chmod 777, modifying .env files, modifying .scenarios/, .validation/, .factory/, CLAUDE.md, or lockfiles.

## Directory Structure

```
project-root/
├── CLAUDE.md                      # Project config + factory rules (edit this)
├── docs/
│   └── prd-template.md            # PRD template (copy and fill in)
│
├── .factory/                      # Orchestration pipeline
│   ├── run.sh                     # Entry point — PRD in, software out
│   ├── orchestrate.sh             # Stage loop — agent, validate, score
│   ├── generate-sprints.sh        # PRD --> sprint task files
│   ├── generate-scenarios.sh      # PRD + tasks --> holdout scenarios
│   ├── next-sprint.sh             # PR, summary, reset, transition
│   └── split-sprints.sh           # Fallback splitter for offline use
│
├── .claude/                       # Claude Code configuration
│   ├── settings.json              # Permissions, hooks, plugins
│   ├── hooks/                     # 6 enforcement hooks
│   ├── commands/                  # 3 slash commands (commit, deploy, todo-all)
│   ├── agents/                    # 4 subagents
│   ├── rules/                     # 3 path-scoped rule files
│   └── skills/tdd-integration/    # TDD enforcement skill
│
├── .scenarios/                    # Holdout validation scenarios (agent can't see)
│   ├── smoke.md                   # Always-on smoke tests
│   └── regression.md              # Accumulated regression tests
│
├── .validation/                   # Validation harness + outputs
│   ├── validate.sh                # Evidence collector + judge prompt builder
│   └── satisfaction-log.jsonl     # Score history across all sprints
│
├── .llm/                          # Agent memory (mutable state)
│   ├── state.md                   # Current agent state
│   ├── todo.md                    # Active sprint task list
│   ├── decisions.md               # Architectural decision log
│   ├── blockers.md                # Blocker log
│   └── exemplars/                 # Reusable code patterns
│
├── .github/workflows/
│   └── claude-review.yml          # Claude Code PR review CI
│
├── .mcp.json                      # MCP server connections
└── .gitignore
```

## Configuration

Before running the factory, edit two files:

### 1. `CLAUDE.md`

This is the project's instruction set. Replace the defaults with your project:

- **Identity**: Project name, stack, repo URL
- **Commands**: Dev, test, lint, and build commands for your stack
- **Code Style**: Your conventions (formatters, patterns, import rules)
- **File Organization**: Your directory layout
- **Critical Rules**: What the agent must never do

The factory rules section (below the `---`) should generally be left as-is.

### 2. `docs/prd.md`

Copy `docs/prd-template.md` and fill it in. Be specific about:

- **Stack**: Exact frameworks and versions (the factory uses this to generate correct tasks)
- **Features**: What the user does, what happens, what the output is
- **Non-goals**: What the product does NOT do (prevents the agent from over-building)

The more specific your PRD, the better the generated sprints will be.

### Optional: `.mcp.json`

Configure MCP servers for additional capabilities:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..." }
    }
  }
}
```

## Key Principles

**PRD is the only input.** Everything else — sprints, tasks, scenarios, code — is generated.

**Validation is blind.** The coding agent cannot see `.scenarios/` or `.validation/`. The judge evaluates against holdout scenarios the agent has never read. This prevents gaming.

**Filesystem is memory.** Agent state persists in `.llm/` files, not in conversation history. Each stage starts fresh with a new Claude session, reads the state files, and picks up where the last stage left off.

**Satisfaction replaces pass/fail.** A 0-10 score gives gradient signal. An 8 means "good enough, keep going." A 4 means "stop and fix the instructions." This is more useful than binary pass/fail for autonomous operation.

**Drift is instruction failure.** When the agent builds the wrong thing, the fix is to improve the PRD or CLAUDE.md — not to manually correct the code.

**Sprints are vertical slices.** Each sprint produces something testable end-to-end. Not "backend sprint then frontend sprint" — each sprint delivers a working feature slice.

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude` command in PATH)
- [Ralph Wiggum plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) for autonomous iteration
- `gh` CLI (optional, for automatic PR creation)
- `tree` command (optional, for directory structure in judge prompts)

## Credits

- [Boris Cherny](https://github.com/anthropics/claude-code) — Claude Code, uglycode patterns
- [StrongDM Software Factory](https://factory.strongdm.ai/) — Scenarios, satisfaction scoring, filesystem-as-memory, pyramid summaries
- [Ralph Wiggum Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) — Official autonomous loop
- [Geoffrey Huntley](https://ghuntley.com) — Ralph Wiggum technique

## License

MIT
