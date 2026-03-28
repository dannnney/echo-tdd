# Echo-TDD Command Design

Date: 2026-03-28
Status: Drafted from interactive brainstorming

## Summary

This design renames the current O-TDD / `testability*` workflow to `Echo-TDD` and standardizes the user-facing command surface around three slash commands:

- `/echo-tdd:plan`
- `/echo-tdd:verify`
- `/echo-tdd:generate`

The goal is to keep the existing three-stage workflow intact while giving it a cleaner name, a more intuitive action-oriented command surface, and a consistent artifact layout.

## Goals

- Rebrand the workflow from O-TDD / `testability*` to `Echo-TDD`
- Preserve the current three-stage structure and responsibility boundaries
- Use action-oriented slash commands that are easy to remember
- Store document artifacts under `docs/echo-tdd`
- Keep executable test code in the project's native test directories
- Support both explicit file input and automatic artifact discovery
- Provide a safe migration path from the existing `testability*` names

## Non-Goals

- Changing the underlying conceptual three-phase workflow
- Merging documentation artifacts and executable scaffold code into the same directory
- Adding more primary subcommands in the first release
- Generating final test code in the `generate` stage

## Command Surface

### `/echo-tdd:plan`

Purpose:
Generate an observability-driven test plan for a feature, workflow, or requirement.

Responsibilities:

- understand the requirement from the prompt, referenced documents, and repository context
- infer trigger channels, observation channels, and validation strategy
- define prerequisites, constraints, and key risks
- write the plan artifact

Primary output:

- `docs/echo-tdd/<topic>/plan.md`

Maps from current workflow:

- `skills/testability/`

### `/echo-tdd:verify`

Purpose:
Verify that the plan is executable in the current environment.

Responsibilities:

- read the plan artifact
- probe environment assumptions and channel availability
- confirm which validation paths are actually usable
- generate minimal helpers, scaffold code, or smoke coverage when needed to prove readiness
- write a verification report that records what passed, failed, or degraded

Primary outputs:

- `docs/echo-tdd/<topic>/verify.md`
- executable helper or scaffold code in the project's native test locations

Maps from current workflow:

- `skills/testability-scaffold/`

### `/echo-tdd:generate`

Purpose:
Generate test cases and data blueprints from the plan and verification results.

Responsibilities:

- read `plan.md` and `verify.md`
- adapt test coverage to the channels that were actually verified
- produce case documents and data blueprints
- avoid generating final executable test code in this stage

Primary output:

- `docs/echo-tdd/<topic>/generate.md`

Maps from current workflow:

- `skills/testability-cases/`

## Command Semantics

The commands are action-oriented, but they still represent a strict workflow chain:

1. `plan` defines the intended observability and validation model
2. `verify` proves which parts of the model are executable in the real environment
3. `generate` expands the validated strategy into concrete cases and data blueprints

This keeps the current phase model intact while exposing user-facing verbs instead of internal phase labels.

## Internal Naming

The internal skill directories should be renamed to match the public command surface:

- `skills/echo-tdd-plan/`
- `skills/echo-tdd-verify/`
- `skills/echo-tdd-generate/`

Recommended mapping:

- `skills/testability/` -> `skills/echo-tdd-plan/`
- `skills/testability-scaffold/` -> `skills/echo-tdd-verify/`
- `skills/testability-cases/` -> `skills/echo-tdd-generate/`

Each skill keeps its own local helper files such as examples, templates, probe guides, and coverage guides. Shared utilities should not be extracted unless duplication becomes painful enough to justify a second refactor.

## Artifact Layout

Document artifacts live under:

- `docs/echo-tdd/<topic>/plan.md`
- `docs/echo-tdd/<topic>/verify.md`
- `docs/echo-tdd/<topic>/generate.md`

Design principles:

- group all workflow documents for a topic in one directory
- keep file names short and stable
- use git history for versioning instead of `v2`, `final`, or timestamped file names
- allow future files such as `notes.md` or `sampling.md` to live beside the three main artifacts

Executable outputs created by `verify` do not go into `docs/`. They stay in the repository's native test locations. `verify.md` should record where those code artifacts were written and what smoke checks were run.

## Topic Resolution

`<topic>` should be a stable kebab-case slug inferred from the user's request.

Resolution order:

1. If the user explicitly names the topic, use that name
2. If a referenced document has a strong title or obvious feature target, derive the slug from that
3. Otherwise infer a concise slug from the current request

Examples:

- "用户注册流程" -> `user-registration`
- "飞书目录同步" -> `feishu-folder-sync`

Before writing any artifact, the workflow should clearly state the resolved target path, for example:

`docs/echo-tdd/feishu-folder-sync/plan.md`

This gives the user one last chance to correct the topic without forcing them to manually name everything in normal cases.

## Input Rules

The workflow should be easy to start and explicit when needed.

Recommended behavior:

- `/echo-tdd:plan`
  - can run with no explicit file argument
  - may use the current conversation and codebase as input
- `/echo-tdd:plan @docs/spec.md`
  - uses the referenced file as the primary requirement source
- `/echo-tdd:verify`
  - auto-discovers the most relevant `plan.md` when possible
- `/echo-tdd:verify @docs/echo-tdd/<topic>/plan.md`
  - uses the provided plan artifact explicitly
- `/echo-tdd:generate`
  - auto-discovers `plan.md` and `verify.md` for the current topic when possible
- `/echo-tdd:generate @docs/echo-tdd/<topic>/verify.md`
  - uses the provided verification artifact explicitly

Rule:

- explicitly provided artifact paths always win over auto-discovery

## Artifact Discovery

### `verify` lookup order

1. user-provided `plan.md`
2. the `plan.md` created in the current conversation
3. the only topic under `docs/echo-tdd/` that contains a `plan.md`
4. if multiple candidates exist, stop and ask the user which topic to continue

### `generate` lookup order

1. user-provided `verify.md`
2. the `verify.md` created in the current conversation
3. a single topic that contains both `plan.md` and `verify.md`
4. if no verified topic exists, stop and tell the user to run `verify` first
5. if multiple verified topics exist, stop and ask the user which topic to continue

## Dependency Rules

- `plan` has no upstream artifact dependency
- `verify` depends on `plan`
- `generate` depends on both `plan` and `verify`

Important nuance:

- `generate` should not require a perfect `verify`
- it should require a completed `verify` artifact that records actual PASS, FAIL, and WARN outcomes
- `generate` must adapt its recommended validation channels to what `verify` proved is available

This preserves forward progress while preventing the workflow from pretending unavailable channels exist.

## Suggested Frontmatter

To make artifact discovery more reliable, each file should include lightweight frontmatter:

```md
---
workflow: echo-tdd
topic: feishu-folder-sync
stage: plan
source_docs:
  - docs/spec.md
depends_on: []
---
```

Examples:

- `verify.md` can use `depends_on: ["./plan.md"]`
- `generate.md` can use `depends_on: ["./plan.md", "./verify.md"]`

This is intentionally minimal. It supports later automation and indexing without forcing a complex schema into the first version.

## Error Handling

The workflow should be permissive about input style but strict about stage dependencies.

Recommended user-facing behavior:

- missing prerequisite artifact
  - "No `verify.md` found for this topic. Run `/echo-tdd:verify` first or pass a verification artifact explicitly."
- multiple topic candidates
  - "Multiple Echo-TDD topics were found. Please choose which topic to continue."
- wrong stage for requested action
  - "A `plan.md` exists, but no `verify.md` exists yet. `generate` cannot run until verification has completed."

This makes the workflow feel stateful and reliable instead of behaving like three unrelated prompts.

## Example Workflow

```text
/echo-tdd:plan @docs/spec.md
-> writes docs/echo-tdd/feishu-folder-sync/plan.md

/echo-tdd:verify
-> reads docs/echo-tdd/feishu-folder-sync/plan.md
-> writes docs/echo-tdd/feishu-folder-sync/verify.md
-> may write helper or scaffold code into the project's test directories

/echo-tdd:generate
-> reads docs/echo-tdd/feishu-folder-sync/plan.md
-> reads docs/echo-tdd/feishu-folder-sync/verify.md
-> writes docs/echo-tdd/feishu-folder-sync/generate.md
```

## Migration Plan

### Phase 1: Introduce new names

- add `echo-tdd-plan`
- add `echo-tdd-verify`
- add `echo-tdd-generate`
- introduce the `/echo-tdd:*` slash command surface

### Phase 2: Keep compatibility aliases

Retain the old names temporarily, but convert them into deprecation wrappers or compatibility shims:

- `testability` -> points users to `echo-tdd-plan`
- `testability-scaffold` -> points users to `echo-tdd-verify`
- `testability-cases` -> points users to `echo-tdd-generate`

### Phase 3: Move examples and references

- migrate examples, templates, and helper docs to the new `echo-tdd-*` directories
- update references in docs and prompts

### Phase 4: Remove the old surface

After a deprecation period, remove the old names once the new command surface is stable and documented.

## Success Criteria

This redesign is successful when:

- users can understand the three commands without learning internal phase jargon
- each command has a clear artifact contract
- the workflow can continue naturally from one step to the next
- artifacts are easy to find under `docs/echo-tdd`
- the old `testability*` names can be retired without confusion
