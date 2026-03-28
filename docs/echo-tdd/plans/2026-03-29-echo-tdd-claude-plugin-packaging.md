# Echo-TDD Claude Plugin Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package this repository as an installable Claude Code plugin marketplace so other Claude Code users can add the marketplace and install `echo-tdd` directly.

**Architecture:** Follow the same repo-root plugin layout used by `other/superpowers`: keep `skills/` and `commands/` at the repository root, add `.claude-plugin/plugin.json` for plugin metadata, add `.claude-plugin/marketplace.json` that exposes the current repo as a one-plugin marketplace using `source: "./"`, and document installation commands in a root `README.md`. Add a shell structure test that verifies the publishable shape and key metadata strings.

**Tech Stack:** Claude Code plugin metadata JSON, Markdown docs, shell-based structure tests

---

### Task 1: Lock the Plugin Packaging Shape with a Failing Test

**Files:**
- Create: `tests/claude-plugin-structure.sh`

- [ ] **Step 1: Write the failing plugin packaging test**

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

assert_exists ".claude-plugin/plugin.json"
assert_exists ".claude-plugin/marketplace.json"
assert_exists "README.md"

assert_contains ".claude-plugin/plugin.json" "\"name\": \"echo-tdd\""
assert_contains ".claude-plugin/plugin.json" "\"version\": \"1.0.0\""
assert_contains ".claude-plugin/marketplace.json" "\"name\": \"echo-tdd-marketplace\""
assert_contains ".claude-plugin/marketplace.json" "\"source\": \"./\""

assert_contains "README.md" "/plugin marketplace add"
assert_contains "README.md" "/plugin install echo-tdd@echo-tdd-marketplace"

echo "Claude plugin packaging checks passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/claude-plugin-structure.sh`
Expected: FAIL because `.claude-plugin/` and `README.md` do not exist yet

- [ ] **Step 3: Commit**

```bash
git add tests/claude-plugin-structure.sh
git commit -m "test: add claude plugin packaging checks"
```

### Task 2: Add Claude Plugin Metadata

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create the plugin metadata directory**

Run: `mkdir -p .claude-plugin`
Expected: `.claude-plugin/` exists at the repository root

- [ ] **Step 2: Add the plugin manifest**

Create `.claude-plugin/plugin.json` with:

```json
{
  "name": "echo-tdd",
  "description": "Observability-driven testing workflow for Claude Code with Echo-TDD plan, verify, and generate commands",
  "version": "1.0.0",
  "author": {
    "name": "dannnney",
    "email": "dannnney@gmail.com"
  },
  "repository": "https://github.com/dannnney/testability",
  "homepage": "https://github.com/dannnney/testability",
  "license": "UNLICENSED",
  "keywords": [
    "claude-code",
    "plugin",
    "skills",
    "testing",
    "observability",
    "echo-tdd"
  ]
}
```

- [ ] **Step 3: Add the marketplace manifest**

Create `.claude-plugin/marketplace.json` with:

```json
{
  "name": "echo-tdd-marketplace",
  "description": "Marketplace for installing the Echo-TDD Claude Code plugin",
  "owner": {
    "name": "dannnney",
    "email": "dannnney@gmail.com"
  },
  "plugins": [
    {
      "name": "echo-tdd",
      "description": "Observability-driven testing workflow for Claude Code with Echo-TDD plan, verify, and generate commands",
      "version": "1.0.0",
      "source": "./",
      "author": {
        "name": "dannnney",
        "email": "dannnney@gmail.com"
      }
    }
  ]
}
```

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "feat: add claude plugin metadata"
```

### Task 3: Add Installation Documentation

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create the root README**

Create `README.md` with:

```md
# Echo-TDD

Echo-TDD is an observability-driven testing workflow for Claude Code. It packages three namespaced commands:

- `/echo-tdd:plan`
- `/echo-tdd:verify`
- `/echo-tdd:generate`

## Installation

In Claude Code, add this repository as a plugin marketplace:

```bash
/plugin marketplace add dannnney/testability
```

Then install the plugin:

```bash
/plugin install echo-tdd@echo-tdd-marketplace
```

## What's Inside

- `skills/echo-tdd-plan/`
- `skills/echo-tdd-verify/`
- `skills/echo-tdd-generate/`
- `commands/echo-tdd-plan.md`
- `commands/echo-tdd-verify.md`
- `commands/echo-tdd-generate.md`
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add claude plugin install instructions"
```

### Task 4: Verify the Publishable Shape

**Files:**
- Modify: `tests/claude-plugin-structure.sh` (only if minor fixes are required)

- [ ] **Step 1: Run the plugin packaging test**

Run: `bash tests/claude-plugin-structure.sh`
Expected: PASS with `Claude plugin packaging checks passed`

- [ ] **Step 2: Re-run the existing Echo-TDD structure test**

Run: `bash tests/echo-tdd-structure.sh`
Expected: PASS with `Echo-TDD structure checks passed`

- [ ] **Step 3: Review staged repository shape**

Run: `find .claude-plugin commands skills -maxdepth 3 -type f | sort`
Expected: plugin metadata plus existing Echo-TDD commands and skills are all present

- [ ] **Step 4: Commit**

```bash
git add tests/claude-plugin-structure.sh README.md .claude-plugin
git commit -m "test: verify claude plugin packaging"
```
