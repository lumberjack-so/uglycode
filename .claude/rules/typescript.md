---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "app/**/*.ts"
  - "app/**/*.tsx"
---
# TypeScript rules
- Use `satisfies` over `as` for type narrowing
- Server components by default; add 'use client' only when needed
- Use Next.js App Router patterns: loading.tsx, error.tsx, not-found.tsx
- API routes use Route Handlers, not pages/api
- Validate all inputs with Zod schemas
