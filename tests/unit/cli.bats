setup() {
    load ../helpers/common
    PGSYNC="$(pgsync_bin)"
}

@test "version prints semver on stderr" {
    run --separate-stderr "$PGSYNC" --version
    [ "$status" -eq 0 ]
    [ "$stderr" = "pgsync 2.1.1" ]
    [ -z "$output" ]
}

@test "help exits 1 and prints usage on stderr" {
    run --separate-stderr "$PGSYNC" --help
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"PostgreSQL logical sync"* ]]
    [[ "$stderr" == *"--source URI"* ]]
}

@test "missing source and target exits 1" {
    run --separate-stderr "$PGSYNC"
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"PostgreSQL logical sync"* ]]
}

@test "missing target exits 1" {
    run --separate-stderr "$PGSYNC" -s 'postgresql://a/db'
    [ "$status" -eq 1 ]
}

@test "unknown flag exits 1" {
    run --separate-stderr "$PGSYNC" -s 'postgresql://a/db' -t 'postgresql://b/db' --nope
    [ "$status" -eq 1 ]
}

@test "pg_dump missing exits 1 with clear error" {
    fake_bin="$(mktemp -d)"
    ln -s "$(command -v bash)" "$fake_bin/bash"
    run --separate-stderr env PATH="$fake_bin" "$PGSYNC" \
        -s 'postgresql://a/db' -t 'postgresql://b/db'
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"pg_dump not found"* ]]
}
