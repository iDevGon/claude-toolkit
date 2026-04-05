---
name: check-and-push
description: Run lint, format, typecheck, then commit and push. Use when asked to "check and push", "lint and commit", or "check-and-push".
metadata:
  author: project
  version: "1.0.0"
---

# Check and Push

Runs the full code quality pipeline, then commits and pushes.

## Steps

### Step 1 — Run /check

Invoke the `check` skill to run lint → format → typecheck. All three must pass before proceeding.

```
Skill(check)
```

### Step 2 — Commit and Push

Only after all checks pass, invoke the `commit` skill to commit and push changes.

```
Skill(commit)
```

## Important

- Do NOT proceed to Step 2 if any check in Step 1 fails
- If checks fail, fix the issues, re-run checks, and only then commit
- The commit message should reflect the actual changes, not just "run checks"
