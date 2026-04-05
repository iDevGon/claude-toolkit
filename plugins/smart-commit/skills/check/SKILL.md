---
name: check
description: Run pnpm lint, format, and typecheck in sequence. Use when asked to "check", "lint", "format", "typecheck", or "run checks".
metadata:
  author: project
  version: "1.0.0"
---

# Check (Lint + Format + Typecheck)

Runs the full code quality pipeline: lint → format → typecheck.

## Steps

### Step 1 — Lint

```bash
pnpm lint
```

Fix any lint errors reported by Biome. Re-run until clean.

### Step 2 — Format

```bash
pnpm format
```

This auto-formats with `--write`. No manual fixes needed.

### Step 3 — Typecheck

```bash
pnpm typecheck
```

Fix any TypeScript type errors. Re-run until clean.

### Step 4 — Report

Tell the user the result of each step (pass/fail) and what was fixed.

## Important

- Run steps sequentially — lint first, then format, then typecheck
- If lint or typecheck fails, fix the issues and re-run that step before moving on
- Do not skip any step even if a previous step fails
