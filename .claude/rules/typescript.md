---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "app/**/*.ts"
  - "app/**/*.tsx"
---

# TypeScript Rules

- Use `interface` over `type` for object shapes
- Strict mode: no `any`, no `as` casts unless absolutely necessary
- Prefer `satisfies` over `as` for type narrowing
- Prefer `const` over `let`, never use `var`
- Use named exports, not default exports
- Async functions must handle errors with try/catch
- Server Components by default; add `"use client"` only when needed
- Use App Router patterns: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`
- Validate API responses and form inputs with Zod schemas
- React components: functional components with hooks only, no class components
- Props: define interface, destructure in function signature
- State: useState for local, context for shared, no prop drilling beyond 2 levels
- File naming: kebab-case for files, PascalCase for components
