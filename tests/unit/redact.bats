setup() {
    load ../helpers/common
    PGSYNC="$(pgsync_bin)"
    SECRET_URI='postgresql://syncuser:s3cret!@db.example.com:5432/app'
    REDACTED_PATTERN='syncuser:\*\*\*@db.example.com:5432/app'
}

@test "dry-run redacts password in source and target URIs" {
    run --separate-stderr "$PGSYNC" -n -s "$SECRET_URI" -t "$SECRET_URI"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"$REDACTED_PATTERN"* ]]
    [[ "$stderr" != *"s3cret!"* ]]
    [[ "$stderr" != *"s3cret\!"* ]]
}

@test "verbose dry-run redacts credentials in pipeline" {
    run --separate-stderr "$PGSYNC" -n -v -s "$SECRET_URI" -t "$SECRET_URI"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"$REDACTED_PATTERN"* ]]
    [[ "$stderr" != *"s3cret!"* ]]
}

@test "URI without password is unchanged in dry-run" {
    local plain='postgresql://syncuser@db.example.com:5432/app'
    run --separate-stderr "$PGSYNC" -n -s "$plain" -t "$plain"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"$plain"* ]]
}
