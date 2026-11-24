# 0002: Use repo-kickoff from a git clone; no packaged release

Date: 2026-11-24
Status: accepted

## Context

repo-kickoff reads its catalog of types (`types/`) at runtime, and teaching an unknown type writes a new folder into that catalog for the user to review and commit. The `shell-cli` target adapter installs only the files in `bin/`, each with no dependency on the rest of the repository, so it can't ship the catalog, and an installed copy has no git history to commit taught types to.

## Decision

`Target: none`. repo-kickoff is used from a git clone: clone the repository and symlink `bin/repo-kickoff` onto `PATH`. The command finds the catalog relative to its own real location, following symlinks. Releases are tags with notes, with no packaged archive.

## Consequences

- The clone is the installation; updating is `git pull`.
- Taught types land in a working copy, ready to review and commit.
- If repo-kickoff ever needs a packaged install, a new target adapter and a plan change are needed.
