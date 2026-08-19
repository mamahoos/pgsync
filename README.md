# pgsync

**One-shot PostgreSQL logical sync** — copy one database to another with `pg_dump | psql` and opinionated defaults.

CLI • Docker • GitHub Actions

Not incremental replication, CDC, or bidirectional sync — always a full logical dump over the wire.

## Quick start

### CLI

Needs Bash 4+ and `pg_dump` / `psql` on `PATH`:

```bash
./pgsync.sh \
  -s 'postgresql://user:pass@source:5432/dbname' \
  -t 'postgresql://user:pass@target:5432/dbname'
```

### Docker

```bash
docker run --rm ghcr.io/mamahoos/pgsync:latest \
  -s 'postgresql://user:pass@source:5432/dbname' \
  -t 'postgresql://user:pass@target:5432/dbname'
```

Images publish on version tags to [GHCR](https://github.com/mamahoos/pgsync/pkgs/container/pgsync). Pin a release, e.g. `ghcr.io/mamahoos/pgsync:2.1.0`.

### GitHub Actions

```yaml
- uses: mamahoos/pgsync@v2
  with:
    source: ${{ secrets.PGSYNC_SOURCE_URI }}
    target: ${{ secrets.PGSYNC_TARGET_URI }}
```

Prefer a pinned semver (`@v2.1.0`) or commit SHA for production. Do not use `@main`.

Reference workflow: [`examples/github-action-sync.yml`](examples/github-action-sync.yml).

Dry-run and verbose output **redact passwords** in connection URIs. Log messages go to **stderr**; stdout stays free for the dump pipe.

## Install

```bash
sudo source ./install.sh               # /usr/local/bin/pgsync
PREFIX="${HOME}/.local" ./install.sh   # user-local
```

Bash tab completion ships with the installer.

## Docker Compose (local demo)

```bash
docker compose run --rm pgsync
```

## Options

| Flag | Meaning |
|------|---------|
| `-s`, `--source` URI | Source connection URI |
| `-t`, `--target` URI | Target connection URI |
| `-n`, `--dry-run` | Print the pipeline; do not run |
| `--delete` | Drop and recreate `public` on target before restore |
| `--schema-only` | Schema without data |
| `--data-only` | Data only (target table must exist; use `--no-clean`) |
| `--no-clean` | Skip `pg_dump --clean --if-exists` |
| `--single-transaction` | Wrap restore in one transaction (`psql -1`) |
| `-q`, `--quiet` | Suppress the final `pgsync: ok` line |
| `-v`, `--verbose` | Show pipeline and server output |
| `-h`, `--help` | Help |
| `-V`, `--version` | Version |

`--source=URI` and `--target=URI` are accepted. Standard libpq env vars apply (`PGPASSWORD`, `PGSSLMODE`, …).

## Tests

```bash
./scripts/test.sh                  # shellcheck + unit tests
INTEGRATION=1 ./scripts/test.sh    # + Postgres integration (needs psql)
```

## License

MIT — see [LICENSE](LICENSE).
