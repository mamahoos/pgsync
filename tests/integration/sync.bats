setup() {
    load ../helpers/common
    export PGSYNC="$(pgsync_bin)"
    export PGSYNC_SOURCE_URI="${PGSYNC_SOURCE_URI:-postgresql://postgres:postgres@localhost:5432/app}"
    export PGSYNC_TARGET_URI="${PGSYNC_TARGET_URI:-postgresql://postgres:postgres@localhost:5433/app}"
    require_psql
    reset_databases
}

@test "full sync copies rows from source to target" {
    seed_source

    run --separate-stderr "$PGSYNC" -q -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"pgsync: ok"* ]]

    [ "$(target_row_count)" = "1" ]
    [ "$(psql_target -tAc "SELECT label FROM pgsync_probe LIMIT 1;")" = "alpha" ]
}

@test "quiet mode suppresses success line" {
    seed_source

    run --separate-stderr "$PGSYNC" -q -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"
    [ "$status" -eq 0 ]
    [[ "$stderr" != *"pgsync: ok"* ]]
}

@test "verbose mode prints exec pipeline" {
    seed_source

    run --separate-stderr "$PGSYNC" -v -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"pgsync: exec:"* ]]
    [[ "$stderr" == *"pg_dump"* ]]
}

@test "delete drops target public schema before restore" {
    seed_source
    psql_target -c '
        CREATE TABLE pgsync_probe (id int PRIMARY KEY, label text);
        INSERT INTO pgsync_probe VALUES (99, '\''stale'\'');
    ' >/dev/null

    run --separate-stderr "$PGSYNC" -q --delete -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"
    [ "$status" -eq 0 ]

    [ "$(target_row_count)" = "1" ]
    [ "$(psql_target -tAc "SELECT label FROM pgsync_probe LIMIT 1;")" = "alpha" ]
}

@test "schema-only sync creates table without copying rows" {
    seed_source

    run --separate-stderr "$PGSYNC" -q --schema-only -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"
    [ "$status" -eq 0 ]

    [ "$(target_has_table)" = "t" ]
    [ "$(target_row_count)" = "0" ]
}

@test "data-only sync copies rows into existing table" {
    seed_source
    psql_target -c '
        CREATE TABLE pgsync_probe (
            id serial PRIMARY KEY,
            label text NOT NULL
        );
    ' >/dev/null

    run --separate-stderr "$PGSYNC" -q --data-only -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"
    [ "$status" -eq 0 ]

    [ "$(target_row_count)" = "1" ]
}

@test "single-transaction wraps restore in one transaction" {
    seed_source

    run --separate-stderr "$PGSYNC" -q --single-transaction \
        -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"
    [ "$status" -eq 0 ]
    [ "$(target_row_count)" = "1" ]
}

@test "second sync is idempotent for unchanged source" {
    seed_source

    "$PGSYNC" -q -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"

    run --separate-stderr "$PGSYNC" -q -s "$PGSYNC_SOURCE_URI" -t "$PGSYNC_TARGET_URI"
    [ "$status" -eq 0 ]
    [ "$(target_row_count)" = "1" ]
}
