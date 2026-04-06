# pgsync

PostgreSQL logical replication in one shot: `pg_dump | psql`, with an `rsync`-shaped CLI and sane defaults (`--no-owner`, `--no-privileges`, `ON_ERROR_STOP` on the target).

## Requirements

- Bash 4+
- `pg_dump` and `psql` on `PATH` (client packages: Debian `postgresql-client`, Fedora `postgresql`, etc.)

## Quick start

```bash
./pgsync.sh \
  -s 'postgresql://user:pass@source:5432/dbname' \
  -t 'postgresql://user:pass@target:5432/dbname'
```

Messages go to **stderr**; the dump stream never touches the script’s stdout (safe for future wrapping).

## Install (any Linux)

From the repo root:

```bash
sudo source ./install.sh
```

Defaults: `PREFIX=/usr/local`, binary `${PREFIX}/bin/pgsync`, completion under the first existing path among:

- `${PREFIX}/share/bash-completion/completions`
- `/usr/share/bash-completion/completions`
- `/usr/local/share/bash-completion/completions`
- `/etc/bash_completion.d`

User-local install (no root):

```bash
PREFIX="${HOME}/.local" ./install.sh
```

Override dirs when needed:

```bash
PREFIX=/opt/pgsync BINDIR=/opt/pgsync/bin COMPDIR=/opt/pgsync/share/bash-completion/completions ./install.sh
```

Dry-run the installer:

```bash
DRY_RUN=1 ./install.sh
```

After install, open a new shell or `source` the completion file printed by the installer so tab completion loads.

## Options

| Flag | Meaning |
|------|---------|
| `-s`, `--source` URI | Source connection URI |
| `-t`, `--target` URI | Target connection URI |
| `-n`, `--dry-run` | Print the pipeline; no `pg_dump` / `psql` |
| `--delete` | `DROP SCHEMA public CASCADE` + `CREATE SCHEMA public` on target before restore |
| `--schema-only` | `pg_dump --schema-only` |
| `--data-only` | `pg_dump --data-only` |
| `--no-clean` | Omit `pg_dump --clean --if-exists` |
| `--single-transaction` | `psql -1` (whole restore in one transaction) |
| `-q`, `--quiet` | Suppress the final `pgsync: ok (…)` line |
| `-v`, `--verbose` | Print the exact pipeline before execution; leave `psql` output visible |
| `-h`, `--help` | Help |
| `-V`, `--version` | Version string |

`--source=URI` and `--target=URI` forms are accepted.

## Compared to rsync (mental model)

| rsync | pgsync |
|-------|--------|
| `-n` / `--dry-run` | `-n` / `--dry-run` |
| `--delete` | `--delete` (target `public` schema) |
| `-q` | `-q` |
| `-v` | `-v` (shows command + server output) |

There is no incremental mode; this is always a full logical dump/restore over the wire.

## Environment

Standard libpq variables apply (`PGPASSWORD`, `PGSSLMODE`, `PGHOST`, …). See `psql` and `pg_dump` documentation.

## Exit codes

Non-zero on bad arguments, missing tools, or `ON_ERROR_STOP` failures from `psql`.

## License

MIT — see [LICENSE](LICENSE).
