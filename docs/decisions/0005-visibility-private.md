# 0005: Keep the repository private

Date: 2026-11-24
Status: superseded by 0012

## Context

idea-to-plan always creates a repository private, while its plan is a draft. The owner kept that when accepting the plan.

## Decision

The repository is private, as `visibility: private` in `.project/config.yml` records.

## Consequences

Only people granted access can see it. Going public later publishes the whole history, and is a deliberate change through accept-the-plan with `visibility=public`, recorded in a record that supersedes this one.
