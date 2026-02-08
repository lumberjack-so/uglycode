---
paths:
  - "api/**/*.py"
  - "services/**/*.py"
---
# Python rules
- Use FastAPI dependency injection for shared resources
- Pydantic v2 models with `model_validator` over root_validator
- Async endpoints by default. Use `asyncio.gather` for concurrent operations.
- SQLAlchemy 2.0 style with `select()`, not legacy `query()`
