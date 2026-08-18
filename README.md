# pgsync

One-shot PostgreSQL logical sync: `pg_dump | psql`. rsync-shaped flags, sane defaults (`--no-owner`, `--no-privileges`, `ON_ERROR_STOP` on the target).

## Quick start

**Script** — needs Bash 4+ and `pg_dump` / `psql` on `PATH`:

```bash
./pgsync.sh \
  -s 'postgresql://user:pass@source:5432/dbname' \
  -t 'postgresql://user:pass@target:5432/dbname'
```

**Docker** — no local Postgres client needed; image includes `pg_dump` and `psql`:

```bash
docker run --rm ghcr.io/mamahoos/pgsync:latest \
  -s 'postgresql://user:pass@source:5432/dbname' \
  -t 'postgresql://user:pass@target:5432/dbname'
```

Published on every version tag (`v*`) to [GHCR](https://github.com/mamahoos/pgsync/pkgs/container/pgsync). Pin a release, e.g. `ghcr.io/mamahoos/pgsync:2.0.0`.

Log output goes to **stderr**; stdout stays free for the dump pipe.

## Install

```bash
sudo source ./install.sh          # system: /usr/local/bin/pgsync
PREFIX="${HOME}/.local" ./install.sh   # user-local, no root
```

Bash tab completion is installed alongside the binary. Open a new shell or `source` the completion file the installer prints.

## Docker Compose (local demo)

Two Postgres instances plus a one-shot sync — useful for smoke tests:

```bash
docker compose run --rm pgsync
```

Custom URIs or a pre-built image:

```bash
docker compose run --rm pgsync \
  -s 'postgresql://user:pass@host:5432/src' \
  -t 'postgresql://user:pass@host:5432/dst'

PGSYNC_IMAGE=ghcr.io/mamahoos/pgsync:latest docker compose run --rm pgsync
```

## Options

| Flag | Meaning |
|------|---------|
| `-s`, `--source` URI | Source connection URI |
| `-t`, `--target` URI | Target connection URI |
| `-n`, `--dry-run` | Print the pipeline; do not run |
| `--delete` | Drop and recreate `public` on target before restore |
| `--schema-only` | Schema without data |
| `--data-only` | Data only (target table must already exist; use `--no-clean`) |
| `--no-clean` | Skip `pg_dump --clean --if-exists` |
| `--single-transaction` | Wrap restore in one transaction (`psql -1`) |
| `-q`, `--quiet` | Suppress the final `pgsync: ok` line |
| `-v`, `--verbose` | Show pipeline and server output |
| `-h`, `--help` | Help |
| `-V`, `--version` | Version |

`--source=URI` and `--target=URI` are accepted. There is no incremental mode — always a full logical dump over the wire.

Standard libpq env vars apply (`PGPASSWORD`, `PGSSLMODE`, …). Non-zero exit on bad args, missing tools, or `psql` errors.

## Tests

```bash
./scripts/test.sh                  # shellcheck + unit tests
INTEGRATION=1 ./scripts/test.sh    # + Postgres integration (needs psql)
```

## License

MIT — see [LICENSE](LICENSE).
