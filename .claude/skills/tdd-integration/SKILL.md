---
name: tdd-integration
description: Enforce test-driven development with strict Red-Green-Refactor cycles. Use when implementing features, fixing bugs, or when the user requests TDD.
allowed-tools: ["Bash", "Read", "Write", "Edit", "MultiEdit", "Grep", "Glob", "Task"]
---
# TDD Integration

## Phase 1: RED — Write a failing test
Before writing any implementation:
1. Identify the behavior to implement
2. Write a test that exercises this behavior
3. Run the test — confirm it FAILS
4. Do NOT proceed until the test fails for the right reason

## Phase 2: GREEN — Minimal implementation
1. Write the minimum code to make the failing test pass
2. Do not add anything beyond what the test requires
3. Run the full test suite — ALL tests must pass
4. Fix implementation (never fix tests to match broken code)

## Phase 3: REFACTOR — Clean up
1. Look for duplication, unclear naming, or unnecessary complexity
2. Refactor only if there's a clear improvement
3. Run tests after every refactor step — they must stay green
4. If no refactoring needed, say so and move on

## Rules
- One test at a time. Never write multiple failing tests.
- Implementation must not exceed test requirements.
- If tests pass on first run, the test may be too trivial — verify it tests real behavior.
