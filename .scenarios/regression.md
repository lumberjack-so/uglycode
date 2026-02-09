# Regression Scenarios

These must pass after EVERY sprint. This file grows as features are completed.
New entries are appended by `.factory/generate-scenarios.sh` after each sprint.

## R-001: Services start without errors
- docker compose up -d completes without errors
- All containers reach healthy state within 60 seconds
- No containers restart-looping

## R-002: Test suite passes
- Full test suite runs with 0 failures
- No skipped tests that were previously passing

## R-003: API health endpoint
- GET /health returns 200
- Response is valid JSON
