# Spec: GitHub Action interface for pgsync

## Objective

Add a **composite GitHub Action** in the same repository as a thin wrapper around `pgsync.sh`. The Action is one distribution interface alongside CLI and Docker — not a replacement for them.

**User stories:**
- As a CI maintainer, I can sync two PostgreSQL databases with `uses: mamahoos/pgsync@v2` and secrets for URIs.
- As an operator, dry-run/verbose output never prints database passwords.
- As a new user, README shows CLI, Docker, and GitHub Actions in under 10 seconds.

## Tech Stack

- Bash 4+ (`pgsync.sh` core)
- Composite Action (`action.yml` at repo root)
- Bats for unit/integration tests
- GitHub Actions + GHCR (existing)

## Commands

```bash
./scripts/test.sh                              # shellcheck + unit tests
INTEGRATION=1 ./scripts/test.sh                # + integration tests
docker build -t pgsync:local .                 # container smoke
```

## Project Structure

```
pgsync.sh              # core sync logic
action.yml             # composite GitHub Action (wrapper only)
examples/              # reference workflows (not executed by CI)
tasks/                 # spec, plan, todo
tests/unit/            # CLI + redaction tests
.github/workflows/     # CI (unchanged triggers except action.yml runs tests)
```

## Code Style

- Single implementation: Action calls `pgsync.sh`; no duplicated pg_dump/psql logic.
- Credentials redacted in any user-visible pipeline output (`dry_show`).
- Action inputs use kebab-case matching CLI flags where possible.

## Testing Strategy

| Level | What | Where |
|-------|------|-------|
| Unit | URI redaction, dry-run output | `tests/unit/redact.bats`, update `dry_run.bats` |
| Unit | CLI unchanged behavior | existing bats |
| Integration | Real sync | existing `tests/integration/` |
| CI | shellcheck includes action if bash embedded | lint job |

## Boundaries

**Always:**
- Redact passwords in dry-run/verbose pipeline display
- Pin Action docs to version tags (`@v2.1.0`), not `@main`
- Keep Action as composite wrapper

**Ask first:**
- Docker-based Action (heavier; defer)
- PostgreSQL version matrix

**Never:**
- Log raw connection URIs with passwords
- Duplicate sync logic in `action.yml`
- Separate repository for the Action

## Success Criteria

- [ ] `action.yml` exists at repo root; composite; all CLI flags exposed as optional inputs
- [ ] `dry_show` redacts `user:password@` in URIs; bats prove password never appears in stderr
- [ ] README repositioned: one-shot sync; CLI • Docker • GitHub Actions; example `uses:` block
- [ ] `examples/github-action-sync.yml` reference workflow
- [ ] Repo description updated on GitHub
- [ ] Version bumped to 2.1.0; unit test updated
- [ ] Tag `v2.1.0` publishes Docker image and floating major tag `v2`
- [ ] `./scripts/test.sh` passes

## Open Questions

- None — same-repo composite Action confirmed by user analysis.
