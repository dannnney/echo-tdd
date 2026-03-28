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
