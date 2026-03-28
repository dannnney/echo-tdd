# Echo-TDD for OpenCode

Complete guide for using Echo-TDD with [OpenCode.ai](https://opencode.ai).

## Installation

Add Echo-TDD to the `plugin` array in your `opencode.json`:

```json
{
  "plugin": ["echo-tdd@git+https://github.com/dannnney/testability.git"]
}
```

Restart OpenCode. The plugin registers the repository `skills/` directory automatically.

## Usage

### Finding Skills

```text
use skill tool to list skills
```

### Loading a Skill

```text
use skill tool to load echo-tdd-plan
```

## How It Works

The plugin registers the repo `skills/` directory via the OpenCode config hook so Echo-TDD skills are discovered without symlinks.
