#!/usr/bin/env bash

set -euo pipefail

#############################################
#
#   ____   ____  ____        _
#  |  _ \ / ___|/ ___| _   _| |__
#  | |_) | |  _ \___ \| | | | '_ \
#  |  __/| |_| |___) | |_| | |_) |
#  |_|    \____|____/ \__, |_|__/
#                      |___/
#
# PostgreSQL Logical Sync Tool
#
# Author: mamahoos
# Modeled after rsync philosophy
#
#############################################

VERSION="1.0.0"

#############################################
# Logging helpers
#############################################

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') | $1"
}

info() {
    log "\033[34m[INFO]\033[0m $1"
}

warn() {
    log "\033[33m[WARN]\033[0m $1"
}

error() {
    log "\033[31m[ERROR]\033[0m $1"
    exit 1
}

success() {
    log "\033[32m[SUCCESS]\033[0m $1"
}

#############################################
# Defaults
#############################################

DELETE=false
DRY_RUN=false

#############################################
# Args parsing
#############################################

usage() {
cat <<EOF

pgsync v$VERSION

Usage:

./pgsync.sh \
  --source "postgresql://user:pass@host:5432/db" \
  --target "postgresql://user:pass@host:5432/db" \
  [--delete] \
  [--dry-run]

Flags:

--delete     Drop target schema before restore
--dry-run    Show what would happen

EOF
exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SRC="$2"; shift 2 ;;
    --target) DST="$2"; shift 2 ;;
    --delete) DELETE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "${SRC:-}" || -z "${DST:-}" ]] && usage

#############################################
# Preflight
#############################################

command -v pg_dump >/dev/null || error "pg_dump not found"
command -v psql >/dev/null || error "psql not found"

info "Source : $SRC"
info "Target : $DST"
info "Delete : $DELETE"
info "DryRun : $DRY_RUN"

#############################################
# Dry run
#############################################

if $DRY_RUN; then
    warn "Dry run enabled — nothing will be executed."

    echo
    echo "Would run:"
    echo "pg_dump --clean --if-exists --no-owner --no-privileges \"$SRC\" | psql \"$DST\""
    echo

    exit 0
fi

#############################################
# Delete target (rsync --delete equivalent)
#############################################

if $DELETE; then
    warn "Dropping public schema on target"

    psql "$DST" <<EOF
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
EOF
fi

#############################################
# Sync
#############################################

info "Starting logical sync..."

pg_dump \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    "$SRC" | psql "$DST"

success "Database synced successfully."
