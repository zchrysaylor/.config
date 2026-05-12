When working in TypeScript:
- When adding a package to a project add it with an install command, instead of manually editing the package json.
- Run check/format/lint commands when you're done making a change. If they don't exist, suggest making them for the project you're in.
- Avoid explicit return types unless absolutely needed.
- `as any` should be an absolute last resort. Always use real type safety. Lean on type inference instead of manually writing new types over and over again.
- Avoid running `dev` or `build` commands. If you really need to, ask first.

Read the full contents of a file every time, never subsets so you don't miss important context.
