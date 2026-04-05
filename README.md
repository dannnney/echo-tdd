# Echo-TDD

Echo-TDD is an observability-driven testing workflow for Vibe Coding, providing three skills:

- `echo-tdd-plan` — generate an observability-driven test plan
- `echo-tdd-verify` — verify that the plan is executable in the current environment
- `echo-tdd-generate` — generate test cases and data blueprints

## Installation

### Claude Code

```bash
claude plugin marketplace add dannnney/echo-tdd
claude plugin install echo-tdd@echo-tdd-marketplace
```

### Codex

Tell Codex:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/dannnney/echo-tdd/refs/heads/main/.codex/INSTALL.md
```

Detailed docs: `docs/README.codex.md`

### OpenCode

Add Echo-TDD to the `plugin` array in `opencode.json`:

```json
{
  "plugin": ["echo-tdd@git+https://github.com/dannnney/echo-tdd.git"]
}
```

Detailed docs: `docs/README.opencode.md`

### Gemini CLI

```bash
gemini extensions install https://github.com/dannnney/echo-tdd
```

### Cursor

This repository includes a `.cursor-plugin/plugin.json` manifest. Install it through Cursor's plugin workflow.

## What's Inside

- `skills/echo-tdd-plan/` — Phase 0-5 interactive workflow for observability plan generation
- `skills/echo-tdd-verify/` — environment probing and scaffold generation
- `skills/echo-tdd-generate/` — test case and data blueprint generation
- `.claude-plugin/` — Claude Code plugin manifest
- `.cursor-plugin/` — Cursor plugin manifest
- `.codex/` — Codex installation guide
- `.opencode/` — OpenCode plugin module
- `plugins/echo-tdd/` — Codex packaged plugin
