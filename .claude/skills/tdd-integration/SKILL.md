# TDD Integration Skill

## Red-Green-Refactor Cycle

### Red: Write a failing test FIRST
- Test describes the expected behavior, not the implementation
- Test must actually fail before you write any production code
- Use descriptive test names: `test_entity_creation_returns_201`

### Green: Implement minimally
- Write the MINIMUM code to make the failing test pass
- Do not add extra features, abstractions, or "nice to haves"
- If you're writing more than 50 lines to pass one test, the test is too big

### Refactor: Clean up (only if needed)
- Only refactor if the code is unclear or duplicated
- Run tests after refactoring to ensure nothing broke
- Do not refactor code outside the current task

## Test Structure (Arrange-Act-Assert)
```python
def test_something():
    # Arrange — set up preconditions
    entity = Entity(name="test")

    # Act — perform the action
    result = service.create(entity)

    # Assert — verify the outcome
    assert result.id is not None
    assert result.name == "test"
```

## Rules
- Every production file gets a corresponding test file
- Test file mirrors source path: `api/services/graph.py` → `tests/services/test_graph.py`
- Integration tests go in `tests/integration/`
- Never mock what you don't own — use fakes or test doubles for external services
