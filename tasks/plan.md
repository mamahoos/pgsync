# Implementation Plan: GitHub Action interface

## Overview

Add composite Action + credential redaction + README/OSS positioning. One core (`pgsync.sh`), three interfaces (CLI, Docker, Action).

## Architecture Decisions

1. **Composite Action** on `ubuntu-latest` — installs `postgresql-client` if missing; delegates to `${{ github.action_path }}/pgsync.sh`.
2. **Credential redaction** in `dry_show` only — runtime still uses real URIs; display uses `redact_uri()`.
3. **Same repo** — Action version tracks git tags (`v2.1.0`); floating `v2` tag updated on release.
4. **examples/** — reference workflow only; not wired into CI triggers.

## Task List

### Phase 1: Security + core display
- [ ] Task 1: `redact_uri()` + update `dry_show` in `pgsync.sh`
- [ ] Task 2: `tests/unit/redact.bats`; fix `dry_run.bats` expectations

### Checkpoint 1
- [ ] `./scripts/test.sh` green

### Phase 2: Action interface
- [ ] Task 3: `action.yml` composite with all inputs
- [ ] Task 4: `examples/github-action-sync.yml`

### Phase 3: OSS packaging
- [ ] Task 5: README reposition + GitHub repo description
- [ ] Task 6: Bump 2.1.0; release workflow floating tag step

### Checkpoint 2
- [ ] Full test suite + tag `v2.1.0` + release

## Risks

| Risk | Mitigation |
|------|------------|
| Password in `%q` escaped output | Test asserts literal password absent |
| Runner lacks pg_dump | Action step installs postgresql-client |
| `@main` usage | README warns; document `@v2` / pinned semver |
