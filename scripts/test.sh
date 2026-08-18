#!/usr/bin/env bash
#
# Run lint + unit tests locally. Set INTEGRATION=1 for Postgres integration tests.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v shellcheck >/dev/null; then
    echo "test: shellcheck not found" >&2
    exit 1
fi

shellcheck pgsync.sh install.sh completions/pgsync.bash scripts/test.sh
shellcheck tests/helpers/common.bash

if ! command -v bats >/dev/null; then
    echo "test: bats not found (install bats-core)" >&2
    exit 1
fi

echo "==> unit tests"
bats tests/unit

if [[ "${INTEGRATION:-0}" == "1" ]]; then
    if ! command -v psql >/dev/null; then
        echo "test: psql not found (required for integration tests)" >&2
        exit 1
    fi
    echo "==> integration tests"
    bats tests/integration
fi

echo "test: ok"
