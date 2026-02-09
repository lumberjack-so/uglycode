---
paths:
  - "api/**/*.py"
  - "services/**/*.py"
---

# Python Rules

- Type hints on ALL function signatures (params and return)
- Use `async def` for any I/O-bound operations
- Pydantic v2 models for all API request/response schemas
- Use `model_validator` for cross-field validation
- FastAPI dependency injection for services
- No bare `except:` — always catch specific exceptions
- Use `pathlib.Path` over `os.path`
- Docstrings on all public functions (Google style)
- No mutable default arguments
- Use `dataclasses` or Pydantic, not raw dicts for structured data
- SQLAlchemy 2.0 style: use `select()` instead of legacy `query()`
- Async by default for database operations
- File naming: snake_case for everything
