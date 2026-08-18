setup() {
    load ../helpers/common
    PGSYNC="$(pgsync_bin)"
    SRC='postgresql://user:pass@source:5432/app'
    DST='postgresql://user:pass@target:5432/app'
}

@test "dry-run prints default pg_dump pipeline" {
    run --separate-stderr "$PGSYNC" -n -s "$SRC" -t "$DST"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"would run:"* ]]
    [[ "$stderr" == *"pg_dump --no-owner --no-privileges --clean --if-exists"* ]]
    [[ "$stderr" == *"psql -v ON_ERROR_STOP=1"* ]]
    [[ "$stderr" == *"$SRC"* ]]
    [[ "$stderr" == *"$DST"* ]]
}

@test "dry-run with --delete mentions public schema reset" {
    run --separate-stderr "$PGSYNC" -n --delete -s "$SRC" -t "$DST"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"drop+create public schema on target"* ]]
}

@test "dry-run --schema-only adds pg_dump flag" {
    run --separate-stderr "$PGSYNC" -n --schema-only -s "$SRC" -t "$DST"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"--schema-only"* ]]
}

@test "dry-run --data-only adds pg_dump flag" {
    run --separate-stderr "$PGSYNC" -n --data-only -s "$SRC" -t "$DST"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"--data-only"* ]]
}

@test "dry-run --no-clean omits clean flags" {
    run --separate-stderr "$PGSYNC" -n --no-clean -s "$SRC" -t "$DST"
    [ "$status" -eq 0 ]
    [[ "$stderr" != *"--clean --if-exists"* ]]
}

@test "dry-run --single-transaction adds psql -1" {
    run --separate-stderr "$PGSYNC" -n --single-transaction -s "$SRC" -t "$DST"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"psql -v ON_ERROR_STOP=1 -1"* ]]
}

@test "equals-form URIs are accepted" {
    run --separate-stderr "$PGSYNC" -n \
        --source="$SRC" --target="$DST"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"$SRC"* ]]
    [[ "$stderr" == *"$DST"* ]]
}

@test "schema-only and data-only together exit 1" {
    run --separate-stderr "$PGSYNC" -s "$SRC" -t "$DST" --schema-only --data-only
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"mutually exclusive"* ]]
}

@test "dry-run verbose prints dry-run banner" {
    run --separate-stderr "$PGSYNC" -n -v -s "$SRC" -t "$DST"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"pgsync: dry-run"* ]]
}
