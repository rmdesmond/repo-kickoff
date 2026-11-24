# 0007: Require no approving reviews while there is one maintainer

Date: 2026-11-24
Status: accepted

## Context

rmdesmond is the only person who can write to the repository. GitHub never counts an author's own approval, and agents open change requests with the maintainer's login, so a required approval would block every merge.

## Decision

`review.required_approvals: 0` and `code_owners: false`. The core checks (lint, build, unit, integration) gate merges, and the maintainer's merge is the review.

## Consequences

Nobody else reviews a change before it merges. When a second maintainer joins, raise `required_approvals` to 1 through a plan change and run accept-the-plan again, with a record superseding this one.
