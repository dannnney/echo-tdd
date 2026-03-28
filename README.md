# Echo-TDD

Echo-TDD is an observability-driven testing workflow centered around three core capabilities:

- `/echo-tdd:plan`
- `/echo-tdd:verify`
- `/echo-tdd:generate`

This repository now follows the same multi-platform packaging strategy as `superpowers`, with install surfaces for Claude Code, Codex, Cursor, Gemini CLI, and OpenCode.

## Installation

### Claude Code

Register the marketplace:

```bash
/plugin marketplace add dannnney/testability
```

Then install:

```bash
/plugin install echo-tdd@echo-tdd-marketplace
```

### Cursor

This repository includes a root `.cursor-plugin/plugin.json` manifest. Publish it through your preferred Cursor plugin distribution path, or install it through Cursor's plugin workflow once the repo is published.

### Codex

Tell Codex:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/dannnney/testability/refs/heads/main/.codex/INSTALL.md
```

Detailed docs: `docs/README.codex.md`

### OpenCode

Add Echo-TDD to the `plugin` array in `opencode.json`:

```json
{
  "plugin": ["echo-tdd@git+https://github.com/dannnney/testability.git"]
}
```

Detailed docs: `docs/README.opencode.md`

### Gemini CLI

```bash
gemini extensions install https://github.com/dannnney/testability
```

## Local Development

### Claude Code local plugin testing

```bash
claude --plugin-dir /absolute/path/to/testability
```

Then run `/reload-plugins` after edits.

### Claude Code local marketplace testing

```text
/plugin marketplace add .
/plugin install echo-tdd@echo-tdd-marketplace --scope local
```

## What's Inside

- `skills/echo-tdd-plan/`
- `skills/echo-tdd-verify/`
- `skills/echo-tdd-generate/`
- `commands/echo-tdd-plan.md`
- `commands/echo-tdd-verify.md`
- `commands/echo-tdd-generate.md`
- `.claude-plugin/`
- `.cursor-plugin/`
- `.codex/`
- `.opencode/`
- `.agents/plugins/marketplace.json`
- `plugins/echo-tdd/`
