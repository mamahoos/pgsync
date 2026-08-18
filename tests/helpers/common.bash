# Shared helpers for bats tests.

bats_require_minimum_version 1.5.0

pgsync_bin() {
    printf '%s' "${BATS_TEST_DIRNAME}/../../pgsync.sh"
}

require_psql() {
    if ! command -v psql >/dev/null; then
        skip "psql not available"
    fi
}

psql_source() {
    psql -v ON_ERROR_STOP=1 "$PGSYNC_SOURCE_URI" "$@"
}

psql_target() {
    psql -v ON_ERROR_STOP=1 "$PGSYNC_TARGET_URI" "$@"
}

reset_databases() {
    psql_source -c 'DROP TABLE IF EXISTS pgsync_probe CASCADE;' >/dev/null
    psql_target -c 'DROP TABLE IF EXISTS pgsync_probe CASCADE;' >/dev/null
}

seed_source() {
    psql_source -c '
        CREATE TABLE pgsync_probe (
            id serial PRIMARY KEY,
            label text NOT NULL
        );
        INSERT INTO pgsync_probe (label) VALUES ('\''alpha'\'');
    ' >/dev/null
}

target_row_count() {
    psql_target -tAc 'SELECT count(*) FROM pgsync_probe;'
}

target_has_table() {
    psql_target -tAc "SELECT to_regclass('public.pgsync_probe') IS NOT NULL;"
}
