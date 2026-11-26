# 0012: Make the repository public

Date: 2026-11-26
Status: accepted

Supersedes 0005.

## Context

0005 kept the repository private while the plan was worked. The owner has since made it public on GitHub, after checking that its contents and history hold nothing sensitive. The owner's name, email address and GitHub login are in the licence, the decision records and the commits, which the owner is happy with. The run logs in `docs/runs/` show local paths from the owner's machine.

## Decision

The repository is public, as `visibility: public` in `.project/config.yml` records.

## Consequences

Anyone can read the repository, including its whole history, its issues, its change requests and its releases. Anything committed from now on is published as soon as it's pushed, so secrets and private details must never be committed. Making it private again needs a new decision record that supersedes this one. Only the owner can write, so the review rule in 0007 still holds.
