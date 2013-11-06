cogdb:new-id() {
    while true; do
        local id=$(< /dev/urandom tr -dc 2-9A-HJ-NP-Z | head -c${1:-4})
        [[ $id =~ [A-Z] ]] && [[ $id =~ [0-9] ]] &&
            [ ! -e "$COGDB_ROOT/node/$id" ] && break
    done
    touch "$COGDB_ROOT/node/$id"
}
