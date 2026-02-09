# Scenario Holdout Set

These files describe what working software looks like from the user's perspective.
The coding agent NEVER reads or modifies this directory (enforced by .claude/settings.json deny rules).
A separate validation agent evaluates the codebase against these scenarios.

## File naming
- `sprint-NN-scenarios.md` — scenarios specific to one sprint
- `regression.md` — scenarios that must ALWAYS pass across all sprints
- `smoke.md` — quick health checks (services up, endpoints respond)

## How scenarios are generated
Run `.factory/generate-scenarios.sh <prd-file> <sprint-number>` to auto-generate from a PRD.

## How scenarios are evaluated
Run `.factory/orchestrate.sh <sprint-number>` which calls `.validation/validate.sh` after each stage.
A separate Claude session acts as an LLM judge, scoring satisfaction 0-10.
