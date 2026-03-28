# Echo-TDD Multi-Platform Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the same multi-platform distribution surface that `other/superpowers` exposes so Echo-TDD can be installed or consumed from Claude Code, Codex, Cursor, Gemini CLI, and OpenCode.

**Architecture:** Keep the current Claude plugin layout at repo root, then add platform-specific entrypoints modeled on `other/superpowers`: Codex install docs plus a Codex marketplace plugin under `plugins/echo-tdd/`, a root Cursor manifest, Gemini extension metadata plus `GEMINI.md`, and an OpenCode plugin module plus install docs. Update the root README to present all supported install paths in one place.

**Tech Stack:** Markdown docs, JSON manifests, minimal Node ESM plugin file for OpenCode, shell-based structure tests

---

### Task 1: Lock the Multi-Platform Packaging Surface with a Failing Test

**Files:**
- Create: `tests/platform-packaging-structure.sh`

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

assert_exists ".cursor-plugin/plugin.json"
assert_exists ".codex/INSTALL.md"
assert_exists "docs/README.codex.md"
assert_exists "gemini-extension.json"
assert_exists "GEMINI.md"
assert_exists ".opencode/INSTALL.md"
assert_exists ".opencode/plugins/echo-tdd.js"
assert_exists "package.json"
assert_exists ".agents/plugins/marketplace.json"
assert_exists "plugins/echo-tdd/.codex-plugin/plugin.json"
assert_exists "plugins/echo-tdd/skills/echo-tdd-plan/SKILL.md"

assert_contains ".cursor-plugin/plugin.json" "\"name\": \"echo-tdd\""
assert_contains "gemini-extension.json" "\"name\": \"echo-tdd\""
assert_contains "GEMINI.md" "@./skills/echo-tdd-plan/SKILL.md"
assert_contains ".codex/INSTALL.md" "~/.agents/skills/echo-tdd"
assert_contains ".opencode/INSTALL.md" "echo-tdd@git+"
assert_contains "package.json" "\"main\": \".opencode/plugins/echo-tdd.js\""
assert_contains ".agents/plugins/marketplace.json" "\"name\": \"echo-tdd\""
assert_contains "plugins/echo-tdd/.codex-plugin/plugin.json" "\"name\": \"echo-tdd\""

echo "Platform packaging checks passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/platform-packaging-structure.sh`
Expected: FAIL because the multi-platform support files do not exist yet

- [ ] **Step 3: Commit**

```bash
git add tests/platform-packaging-structure.sh
git commit -m "test: add multi-platform packaging checks"
```

### Task 2: Add Codex Support

**Files:**
- Create: `.codex/INSTALL.md`
- Create: `docs/README.codex.md`
- Create: `.agents/plugins/marketplace.json`
- Create: `plugins/echo-tdd/.codex-plugin/plugin.json`
- Create: `plugins/echo-tdd/skills/`

- [ ] **Step 1: Scaffold the Codex plugin directory**

Run:

```bash
python3 /Users/danney/.codex/skills/.system/plugin-creator/scripts/create_basic_plugin.py \
  echo-tdd \
  --path ./plugins \
  --with-skills \
  --with-marketplace \
  --force
```

Expected: `plugins/echo-tdd/.codex-plugin/plugin.json` and `.agents/plugins/marketplace.json` exist

- [ ] **Step 2: Replace plugin manifest placeholders with Echo-TDD metadata**

Update `plugins/echo-tdd/.codex-plugin/plugin.json` so it includes real Echo-TDD metadata and points to `./skills/`.

- [ ] **Step 3: Copy active Echo-TDD skills into the Codex plugin**

Run:

```bash
mkdir -p plugins/echo-tdd/skills
cp -R skills/echo-tdd-plan plugins/echo-tdd/skills/
cp -R skills/echo-tdd-verify plugins/echo-tdd/skills/
cp -R skills/echo-tdd-generate plugins/echo-tdd/skills/
```

Expected: the plugin contains its own installable skill set

- [ ] **Step 4: Write Codex install docs**

Create `.codex/INSTALL.md` and `docs/README.codex.md` modeled on `other/superpowers`, but for Echo-TDD:

- clone to `~/.codex/echo-tdd`
- symlink `~/.agents/skills/echo-tdd` to the repo `skills/` directory
- mention the marketplace plugin as an optional advanced path

- [ ] **Step 5: Commit**

```bash
git add .codex docs/README.codex.md .agents plugins
git commit -m "feat: add codex packaging support"
```

### Task 3: Add Cursor and Gemini Support

**Files:**
- Create: `.cursor-plugin/plugin.json`
- Create: `gemini-extension.json`
- Create: `GEMINI.md`

- [ ] **Step 1: Add the Cursor plugin manifest**

Create `.cursor-plugin/plugin.json` modeled on `other/superpowers` and point it at:

- `./skills/`
- `./commands/`

- [ ] **Step 2: Add Gemini extension metadata**

Create `gemini-extension.json` with Echo-TDD name, description, version, and `contextFileName: "GEMINI.md"`.

- [ ] **Step 3: Add `GEMINI.md`**

Create a minimal root `GEMINI.md` that references:

- `@./skills/echo-tdd-plan/SKILL.md`
- `@./skills/echo-tdd-verify/SKILL.md`
- `@./skills/echo-tdd-generate/SKILL.md`

- [ ] **Step 4: Commit**

```bash
git add .cursor-plugin gemini-extension.json GEMINI.md
git commit -m "feat: add cursor and gemini packaging"
```

### Task 4: Add OpenCode Support

**Files:**
- Create: `.opencode/INSTALL.md`
- Create: `.opencode/plugins/echo-tdd.js`
- Create: `docs/README.opencode.md`
- Create: `package.json`

- [ ] **Step 1: Add the OpenCode plugin module**

Create `.opencode/plugins/echo-tdd.js` as a minimal ESM plugin that registers the repo `skills/` directory through the OpenCode config hook.

- [ ] **Step 2: Add the OpenCode install docs**

Create `.opencode/INSTALL.md` and `docs/README.opencode.md` modeled on `other/superpowers`, but using `echo-tdd@git+<repo-url>` examples and Echo-TDD-specific usage examples.

- [ ] **Step 3: Add a minimal package manifest**

Create `package.json` with:

```json
{
  "name": "echo-tdd",
  "version": "1.0.0",
  "type": "module",
  "main": ".opencode/plugins/echo-tdd.js"
}
```

- [ ] **Step 4: Commit**

```bash
git add .opencode docs/README.opencode.md package.json
git commit -m "feat: add opencode packaging"
```

### Task 5: Update README and Verify Everything

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Expand the root README to cover all supported platforms**

Add sections for:

- Claude Code
- Cursor
- Codex
- OpenCode
- Gemini CLI

Model the installation matrix on `other/superpowers/README.md`, but keep content specific to Echo-TDD.

- [ ] **Step 2: Run the platform packaging test**

Run: `bash tests/platform-packaging-structure.sh`
Expected: PASS with `Platform packaging checks passed`

- [ ] **Step 3: Re-run existing tests**

Run:

```bash
bash tests/claude-plugin-structure.sh
bash tests/echo-tdd-structure.sh
python3 -m json.tool .cursor-plugin/plugin.json >/dev/null
python3 -m json.tool gemini-extension.json >/dev/null
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/echo-tdd/.codex-plugin/plugin.json >/dev/null
node --check .opencode/plugins/echo-tdd.js
```

Expected: all commands succeed

- [ ] **Step 4: Commit**

```bash
git add README.md tests/platform-packaging-structure.sh
git commit -m "test: verify multi-platform packaging"
```
