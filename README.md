# Echo-TDD

Echo-TDD is an observability-driven testing workflow for Claude Code. It packages three namespaced commands:

- `/echo-tdd:plan`
- `/echo-tdd:verify`
- `/echo-tdd:generate`

The repository itself is structured as a Claude Code plugin marketplace, following the same repo-root layout used by `superpowers`: plugin metadata lives in `.claude-plugin/`, while the active `skills/` and `commands/` stay at the repository root.

## Install in Claude Code

After publishing this repository to GitHub, add it as a marketplace in Claude Code:

```bash
/plugin marketplace add <github-user>/testability
```

Then install the plugin from that marketplace:

```bash
/plugin install echo-tdd@echo-tdd-marketplace
```

Once installed, Claude Code will expose:

- `/echo-tdd:plan`
- `/echo-tdd:verify`
- `/echo-tdd:generate`

## What's Inside

- `skills/echo-tdd-plan/`
- `skills/echo-tdd-verify/`
- `skills/echo-tdd-generate/`
- `commands/echo-tdd-plan.md`
- `commands/echo-tdd-verify.md`
- `commands/echo-tdd-generate.md`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
