# Installing Echo-TDD for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add Echo-TDD to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["echo-tdd@git+https://github.com/dannnney/testability.git"]
}
```

Restart OpenCode. The plugin auto-installs and registers the Echo-TDD skills directory automatically.

## Usage

Use OpenCode's native `skill` tool to list or load Echo-TDD skills:

```text
use skill tool to list skills
use skill tool to load echo-tdd-plan
```

## Updating

Echo-TDD updates automatically when you restart OpenCode.

To pin a specific version:

```json
{
  "plugin": ["echo-tdd@git+https://github.com/dannnney/testability.git#v1.0.0"]
}
```
