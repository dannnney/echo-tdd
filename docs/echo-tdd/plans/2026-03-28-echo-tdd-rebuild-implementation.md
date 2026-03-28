# Echo-TDD Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the repository's active testing workflow as Echo-TDD by backing up the old `skills/` tree, generating new `echo-tdd-*` skills, and adding slash command entry docs for `plan`, `verify`, and `generate`.

**Architecture:** Keep the old workflow content available under `skills-bak/` as a repository backup, then create a clean new `skills/` tree containing only `echo-tdd-plan`, `echo-tdd-verify`, and `echo-tdd-generate`. Add a root `commands/` directory whose files map the `/echo-tdd:*` command surface to the corresponding skills and document the intended artifact flow under `docs/echo-tdd/<topic>/`.

**Tech Stack:** Markdown skills, Markdown command docs, shell-based repository structure test

---

### Task 1: Lock the Target Structure with a Failing Test

**Files:**
- Create: `tests/echo-tdd-structure.sh`

- [ ] **Step 1: Write the failing structure test**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_exists() {
  local path="$1"
  if [[ ! -e "$ROOT/$path" ]]; then
    echo "Missing expected path: $path" >&2
    exit 1
  fi
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  if ! rg -q --fixed-strings "$pattern" "$ROOT/$path"; then
    echo "Expected '$pattern' in $path" >&2
    exit 1
  fi
}

assert_exists "skills-bak/testability/SKILL.md"
assert_exists "skills-bak/testability-scaffold/SKILL.md"
assert_exists "skills-bak/testability-cases/SKILL.md"

assert_exists "skills/echo-tdd-plan/SKILL.md"
assert_exists "skills/echo-tdd-verify/SKILL.md"
assert_exists "skills/echo-tdd-generate/SKILL.md"

assert_exists "commands/echo-tdd-plan.md"
assert_exists "commands/echo-tdd-verify.md"
assert_exists "commands/echo-tdd-generate.md"

assert_contains "skills/echo-tdd-plan/SKILL.md" "name: echo-tdd-plan"
assert_contains "skills/echo-tdd-plan/SKILL.md" "/echo-tdd:plan"
assert_contains "skills/echo-tdd-plan/SKILL.md" "docs/echo-tdd/<topic>/plan.md"

assert_contains "skills/echo-tdd-verify/SKILL.md" "name: echo-tdd-verify"
assert_contains "skills/echo-tdd-verify/SKILL.md" "/echo-tdd:verify"
assert_contains "skills/echo-tdd-verify/SKILL.md" "docs/echo-tdd/<topic>/verify.md"

assert_contains "skills/echo-tdd-generate/SKILL.md" "name: echo-tdd-generate"
assert_contains "skills/echo-tdd-generate/SKILL.md" "/echo-tdd:generate"
assert_contains "skills/echo-tdd-generate/SKILL.md" "docs/echo-tdd/<topic>/generate.md"

assert_contains "commands/echo-tdd-plan.md" "/echo-tdd:plan"
assert_contains "commands/echo-tdd-verify.md" "/echo-tdd:verify"
assert_contains "commands/echo-tdd-generate.md" "/echo-tdd:generate"

echo "Echo-TDD structure checks passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/echo-tdd-structure.sh`
Expected: FAIL because `skills-bak/`, the new `skills/echo-tdd-*` directories, and the `commands/` files do not exist yet

- [ ] **Step 3: Commit**

```bash
git add tests/echo-tdd-structure.sh
git commit -m "test: add echo-tdd structure checks"
```

### Task 2: Back Up the Existing Skills Tree and Create the New Active Skills Layout

**Files:**
- Modify: `skills/`
- Create: `skills-bak/`
- Create: `skills/echo-tdd-plan/SKILL.md`
- Create: `skills/echo-tdd-plan/dimensions.md`
- Create: `skills/echo-tdd-plan/output-template.md`
- Create: `skills/echo-tdd-plan/examples/api-no-db-access.md`
- Create: `skills/echo-tdd-plan/examples/cli-remote-api.md`
- Create: `skills/echo-tdd-plan/examples/frontend-remote-api.md`
- Create: `skills/echo-tdd-plan/examples/local-fullstack.md`
- Create: `skills/echo-tdd-plan/examples/microservice-single.md`
- Create: `skills/echo-tdd-plan/examples/quant-trading.md`
- Create: `skills/echo-tdd-verify/SKILL.md`
- Create: `skills/echo-tdd-verify/probe-patterns.md`
- Create: `skills/echo-tdd-verify/scaffold-guide.md`
- Create: `skills/echo-tdd-verify/examples/cli-feishu-scaffold.md`
- Create: `skills/echo-tdd-generate/SKILL.md`
- Create: `skills/echo-tdd-generate/coverage-patterns.md`
- Create: `skills/echo-tdd-generate/data-blueprint-guide.md`
- Create: `skills/echo-tdd-generate/output-template.md`
- Create: `skills/echo-tdd-generate/examples/cli-feishu-cases.md`

- [ ] **Step 1: Back up the current active `skills/` tree**

Run: `mv skills skills-bak && mkdir -p skills`
Expected: existing `testability*` content moves under `skills-bak/`, and a new empty `skills/` directory exists

- [ ] **Step 2: Create the new Echo-TDD skill directories**

Run: `mkdir -p skills/echo-tdd-plan/examples skills/echo-tdd-verify/examples skills/echo-tdd-generate/examples`
Expected: the three new active skill directories and their example subdirectories exist

- [ ] **Step 3: Rewrite the phase-one skill as Echo-TDD Plan**

Create `skills/echo-tdd-plan/SKILL.md` with:

```md
---
name: echo-tdd-plan
description: Generate an Echo-TDD observability-driven test plan from requirements, repository context, and available channels. Use when defining how a system should be triggered, observed, and validated.
---
```

Update the body so it:

- refers to `/echo-tdd:plan` instead of `/testability`
- saves the primary artifact under `docs/echo-tdd/<topic>/plan.md`
- points phase-two handoff to `/echo-tdd:verify`
- describes the stage as Echo-TDD Plan rather than Testability

- [ ] **Step 4: Rewrite the phase-two skill as Echo-TDD Verify**

Create `skills/echo-tdd-verify/SKILL.md` with:

```md
---
name: echo-tdd-verify
description: Verify that an Echo-TDD plan is executable in the current environment, record channel availability, and generate minimal scaffold code or smoke coverage when needed.
---
```

Update the body so it:

- refers to `/echo-tdd:verify`
- expects `docs/echo-tdd/<topic>/plan.md` as its primary document input
- records its document output as `docs/echo-tdd/<topic>/verify.md`
- points phase-three handoff to `/echo-tdd:generate`

- [ ] **Step 5: Rewrite the phase-three skill as Echo-TDD Generate**

Create `skills/echo-tdd-generate/SKILL.md` with:

```md
---
name: echo-tdd-generate
description: Generate Echo-TDD test cases and data blueprints from a validated plan and verification report, adapting to the channels that were actually confirmed.
---
```

Update the body so it:

- refers to `/echo-tdd:generate`
- expects `plan.md` plus `verify.md`
- records its output as `docs/echo-tdd/<topic>/generate.md`
- consistently uses Echo-TDD terminology

- [ ] **Step 6: Copy and retarget the supporting reference files**

Run these commands:

```bash
cp skills-bak/testability/dimensions.md skills/echo-tdd-plan/dimensions.md
cp skills-bak/testability/output-template.md skills/echo-tdd-plan/output-template.md
cp -R skills-bak/testability/examples/. skills/echo-tdd-plan/examples/
cp skills-bak/testability-scaffold/probe-patterns.md skills/echo-tdd-verify/probe-patterns.md
cp skills-bak/testability-scaffold/scaffold-guide.md skills/echo-tdd-verify/scaffold-guide.md
cp -R skills-bak/testability-scaffold/examples/. skills/echo-tdd-verify/examples/
cp skills-bak/testability-cases/coverage-patterns.md skills/echo-tdd-generate/coverage-patterns.md
cp skills-bak/testability-cases/data-blueprint-guide.md skills/echo-tdd-generate/data-blueprint-guide.md
cp skills-bak/testability-cases/output-template.md skills/echo-tdd-generate/output-template.md
cp -R skills-bak/testability-cases/examples/. skills/echo-tdd-generate/examples/
```

Expected: all non-SKILL support files exist under the new active Echo-TDD directories

- [ ] **Step 7: Update copied support files to use Echo-TDD names and paths**

Replace old references such as:

- `testability` -> `echo-tdd-plan` where the active skill name is intended
- `/testability` -> `/echo-tdd:plan`
- `/testability-scaffold` -> `/echo-tdd:verify`
- `/testability-cases` -> `/echo-tdd:generate`
- `docs/observability.md` -> `docs/echo-tdd/<topic>/plan.md`

Also update the stage transition text so the active workflow consistently points to `plan -> verify -> generate`.

- [ ] **Step 8: Commit**

```bash
git add skills skills-bak
git commit -m "feat: rebuild skills as echo-tdd"
```

### Task 3: Add Slash Command Entry Docs for the New Echo-TDD Surface

**Files:**
- Create: `commands/echo-tdd-plan.md`
- Create: `commands/echo-tdd-verify.md`
- Create: `commands/echo-tdd-generate.md`

- [ ] **Step 1: Create the new command directory**

Run: `mkdir -p commands`
Expected: root `commands/` directory exists

- [ ] **Step 2: Add the `/echo-tdd:plan` entry doc**

Create `commands/echo-tdd-plan.md` with:

```md
---
description: "Generate an Echo-TDD plan from requirements, docs, and repository context"
---

Use the `echo-tdd-plan` skill.

Preferred artifact path: `docs/echo-tdd/<topic>/plan.md`
```

- [ ] **Step 3: Add the `/echo-tdd:verify` entry doc**

Create `commands/echo-tdd-verify.md` with:

```md
---
description: "Verify an Echo-TDD plan against the current environment and record executable channels"
---

Use the `echo-tdd-verify` skill.

Preferred artifact path: `docs/echo-tdd/<topic>/verify.md`
```

- [ ] **Step 4: Add the `/echo-tdd:generate` entry doc**

Create `commands/echo-tdd-generate.md` with:

```md
---
description: "Generate Echo-TDD test cases and data blueprints from a plan and verification results"
---

Use the `echo-tdd-generate` skill.

Preferred artifact path: `docs/echo-tdd/<topic>/generate.md`
```

- [ ] **Step 5: Commit**

```bash
git add commands
git commit -m "feat: add echo-tdd command docs"
```

### Task 4: Verify the Rebuild and Check for Stale Active References

**Files:**
- Modify: `tests/echo-tdd-structure.sh` (only if small fixes are needed after the first run)

- [ ] **Step 1: Run the structure test and verify it passes**

Run: `bash tests/echo-tdd-structure.sh`
Expected: PASS with `Echo-TDD structure checks passed`

- [ ] **Step 2: Check for stale active references to the old workflow names**

Run: `rg -n "/testability|/testability-scaffold|/testability-cases|name: testability|name: testability-scaffold|name: testability-cases" skills commands`
Expected: no matches in the new active `skills/` tree or `commands/`

- [ ] **Step 3: Review the final diff**

Run: `git status --short && git diff --stat`
Expected: only the intended Echo-TDD rebuild changes appear in the worktree

- [ ] **Step 4: Commit**

```bash
git add tests/echo-tdd-structure.sh skills commands
git commit -m "test: verify echo-tdd rebuild"
```
