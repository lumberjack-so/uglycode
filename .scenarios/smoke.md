# Smoke Test Scenarios

## S-SMOKE-01: API responds
- Start all services
- GET /health returns 200 with {"status": "ok"}
- Response time < 2 seconds

## S-SMOKE-02: Database connected
- Start all services
- GET /health/db returns 200
- Response includes connection confirmation

## S-SMOKE-03: Frontend loads
- Start all services
- GET / returns 200
- Response contains valid HTML with a title tag

## S-SMOKE-04: No containers crash-looping
- docker compose ps shows all services as "running" or "healthy"
- No containers have restarted more than once
