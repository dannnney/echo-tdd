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
