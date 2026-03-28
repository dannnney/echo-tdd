# Echo-TDD for Codex

Guide for using Echo-TDD with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/dannnney/testability/refs/heads/main/.codex/INSTALL.md
```

## Manual Installation

### Prerequisites

- OpenAI Codex
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/dannnney/testability.git ~/.codex/echo-tdd
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/echo-tdd/skills ~/.agents/skills/echo-tdd
   ```

3. Restart Codex.

## How It Works

Codex discovers skills from `~/.agents/skills/`. Echo-TDD becomes available through a single symlink:

```text
~/.agents/skills/echo-tdd/ -> ~/.codex/echo-tdd/skills/
```

This exposes:

- `echo-tdd-plan`
- `echo-tdd-verify`
- `echo-tdd-generate`

## Updating

```bash
cd ~/.codex/echo-tdd && git pull
```

## Uninstalling

```bash
rm ~/.agents/skills/echo-tdd
```
