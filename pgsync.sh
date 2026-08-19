#!/usr/bin/env bash
#
#   ____   ____  ____        _
#  |  _ \ / ___|/ ___| _   _| |__
#  | |_) | |  _ \___ \| | | | '_ \
#  |  __/| |_| |___) | |_| | |_) |
#  |_|    \____|____/ \__, |_|__/
#                      |___/   ~ logical sync ~
#
set -euo pipefail

VERSION="2.1.1"

QUIET=false
VERBOSE=false
DELETE=false
DRY_RUN=false
SCHEMA_ONLY=false
DATA_ONLY=false
NO_CLEAN=false
SINGLE_TXN=false

SRC=""
DST=""

#############################################
# stderr-only (stdout reserved for dump pipe)
#############################################

say() {
    printf '%s\n' "$*" >&2
}

die() {
    say "pgsync: $*"
    exit 1
}

vmsg() {
    $VERBOSE || return 0
    say "pgsync: $*"
}

# Hide credentials in logged URIs (dry-run / verbose pipeline).
redact_uri() {
    local uri="$1"
    if [[ "$uri" =~ ^postgres(ql)?://[^:/@]+:[^@]+@ ]]; then
        printf '%s' "$uri" | sed -E 's#^(postgres(ql)?://[^:/@]+):[^@]*@#\1:***@#'
    else
        printf '%s' "$uri"
    fi
}

#############################################
usage() {
    cat <<'EOF' >&2

pgsync — PostgreSQL logical sync (pg_dump | psql)

  pgsync -s URI -t URI [options]

  -s, --source URI     source cluster (pg connection URI)
  -t, --target URI     target cluster
  -n, --dry-run        print actions only
      --delete         DROP SCHEMA public CASCADE on target before restore
      --schema-only    pg_dump --schema-only
      --data-only      pg_dump --data-only
      --no-clean           omit pg_dump --clean --if-exists
      --single-transaction psql -1 (wrap restore in one transaction)

  -q, --quiet          errors only
  -v, --verbose        show pipeline before run + psql output
  -h, --help
  -V, --version

EOF
    exit 1
}

#############################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -V|--version) say "pgsync $VERSION"; exit 0 ;;
        -q|--quiet) QUIET=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        --delete) DELETE=true; shift ;;
        --schema-only) SCHEMA_ONLY=true; shift ;;
        --data-only) DATA_ONLY=true; shift ;;
        --no-clean) NO_CLEAN=true; shift ;;
        --single-transaction) SINGLE_TXN=true; shift ;;
        -s|--source) SRC="$2"; shift 2 ;;
        -t|--target) DST="$2"; shift 2 ;;
        --source=*)
            SRC="${1#*=}"; shift ;;
        --target=*)
            DST="${1#*=}"; shift ;;
        *) usage ;;
    esac
done

[[ -n "$SRC" && -n "$DST" ]] || usage

if $SCHEMA_ONLY && $DATA_ONLY; then
    die "--schema-only and --data-only are mutually exclusive"
fi

PGDUMP=(pg_dump --no-owner --no-privileges)
if ! $NO_CLEAN; then
    PGDUMP+=(--clean --if-exists)
fi
if $SCHEMA_ONLY; then
    PGDUMP+=(--schema-only)
fi
if $DATA_ONLY; then
    PGDUMP+=(--data-only)
fi
PGDUMP+=("$SRC")

PSQL=(psql -v ON_ERROR_STOP=1)
if $SINGLE_TXN; then
    PSQL+=(-1)
fi
PSQL+=("$DST")

#############################################
dry_show() {
    local arg
    printf '  ' >&2
    for arg in "${PGDUMP[@]}"; do
        [[ "$arg" == "$SRC" ]] && arg="$(redact_uri "$SRC")"
        printf '%q ' "$arg" >&2
    done
    printf ' | ' >&2
    for arg in "${PSQL[@]}"; do
        [[ "$arg" == "$DST" ]] && arg="$(redact_uri "$DST")"
        printf '%q ' "$arg" >&2
    done
    printf '\n' >&2
}

if $DRY_RUN; then
    vmsg "dry-run"
    say "would run:"
    dry_show
    if $DELETE; then
        say "would also: drop+create public schema on target"
    fi
    exit 0
fi

command -v pg_dump >/dev/null || die "pg_dump not found"
command -v psql >/dev/null || die "psql not found"

t0=$SECONDS

if $DELETE; then
    vmsg "dropping public on target"
    $QUIET || psql -v ON_ERROR_STOP=1 "$DST" <<'EOSQL' >/dev/null
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
EOSQL
fi

vmsg "syncing"
if $VERBOSE; then
    say "pgsync: exec:"
    dry_show
    "${PGDUMP[@]}" | "${PSQL[@]}"
else
    "${PGDUMP[@]}" | "${PSQL[@]}" >/dev/null
fi

dt=$((SECONDS - t0))
$QUIET || say "pgsync: ok (${dt}s)"

exit 0
