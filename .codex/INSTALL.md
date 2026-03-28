# Installing Echo-TDD for Codex

Enable Echo-TDD skills in Codex via native skill discovery. Clone the repository and symlink its active `skills/` directory.

## Prerequisites

- Git

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dannnney/testability.git ~/.codex/echo-tdd
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/echo-tdd/skills ~/.agents/skills/echo-tdd
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\echo-tdd" "$env:USERPROFILE\.codex\echo-tdd\skills"
   ```

3. **Restart Codex** to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/echo-tdd
```

You should see a symlink (or junction on Windows) pointing to the Echo-TDD skills directory.

## Updating

```bash
cd ~/.codex/echo-tdd && git pull
```

## Uninstalling

```bash
rm ~/.agents/skills/echo-tdd
```

Optionally delete the clone:

```bash
rm -rf ~/.codex/echo-tdd
```
