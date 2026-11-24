# 0003: Teach unknown types with claude -p, teach first then generate

Date: 2026-11-24
Status: accepted

## Context

repo-kickoff only knows the types in its catalog. For an unknown type it needs an AI assistant to add the type, so later requests need no AI. Options considered: `claude -p` (Claude Code without an interactive session), the Anthropic API called directly, and the Claude Agent SDK. The API would mean rebuilding file writing and the agent loop; the SDK adds a Python or Node dependency to a bash tool.

## Decision

- Use `claude -p`, with `--permission-mode acceptEdits`, `--add-dir` limited to the catalog, and a limited tool list.
- **Teach first, then generate.** The AI writes only the type definition, `types/<type>/`. repo-kickoff then checks it with the type checker and generates the target repository through its normal AI-free path. A type that fails the check is removed.
- **Swappable AI command.** The command comes from `REPO_KICKOFF_AI`, defaulting to `claude -p`. Automated tests use a fake AI, so the unknown-type path is tested on every change without network or credentials.
- Taught types are left in the local clone for the user to review and commit.

## Consequences

- The first use of a taught type follows the same path as every later use, so a broken definition fails at once.
- Teaching needs `claude` installed and signed in; known types don't.
- The real `claude` can only be exercised by hand (T-015), not in CI.
