#!/usr/bin/env bash
#
#  install pgsync + bash completion (POSIX-ish, any distro)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="pgsync"
SRC_SH="${ROOT}/pgsync.sh"
COMP_SRC="${ROOT}/completions/pgsync.bash"

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
COMPDIR="${COMPDIR:-}"

usage() {
    cat <<'EOF' >&2
Usage: ./install.sh [options]

  PREFIX=/path     default: /usr/local  (user: PREFIX=~/.local ./install.sh)
  BINDIR=...       default: PREFIX/bin
  COMPDIR=...      auto if unset
  DRY_RUN=1        print actions only

EOF
    exit 1
}

[[ -f "$SRC_SH" ]] || { echo "install: missing ${SRC_SH}" >&2; exit 1; }
[[ -f "$COMP_SRC" ]] || { echo "install: missing ${COMP_SRC}" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        *) usage ;;
    esac
done

pick_compdir() {
    if [[ -n "$COMPDIR" ]]; then
        echo "$COMPDIR"
        return
    fi
    for d in \
        "${PREFIX}/share/bash-completion/completions" \
        /usr/share/bash-completion/completions \
        /usr/local/share/bash-completion/completions \
        /etc/bash_completion.d
    do
        if [[ -d "$d" ]]; then
            echo "$d"
            return
        fi
    done
    echo "${PREFIX}/share/bash-completion/completions"
}

COMPDIR="$(pick_compdir)"
DRY="${DRY_RUN:-0}"

run() {
    if [[ "$DRY" == "1" ]]; then
        printf '[dry-run] '; printf '%q ' "$@"; echo
    else
        "$@"
    fi
}

echo "pgsync install"
echo "  bin:     ${BINDIR}/${NAME}"
echo "  compl:   ${COMPDIR}/${NAME}"
echo

run mkdir -p "$BINDIR" "$COMPDIR"
run install -m 0755 "$SRC_SH" "${BINDIR}/${NAME}"
run install -m 0644 "$COMP_SRC" "${COMPDIR}/${NAME}"

if [[ "$DRY" != "1" ]]; then
    cat <<EOF

  done. ensure ${BINDIR} is in PATH.
  completion: new shell, or: source ${COMPDIR}/${NAME}

EOF
fi
