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
