# 0006: Squash merges and trunk-based releases

Date: 2026-11-24
Status: accepted

## Context

Each change request is one issue and one plan task, titled as a Conventional Commit. The changelog and version bumps are derived from those titles.

## Decision

- Merge change requests by squashing only; the squash commit takes the change request's title and description. Merge commits and rebase merges are off.
- Delete branches when they merge.
- Release from the default branch (`strategy: trunk`), tagging `v<major>.<minor>.<patch>` with semantic versioning.

## Consequences

The default branch has one commit per change request, whose subject feeds the changelog. Release branches would need a new record.
