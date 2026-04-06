# bash completion for pgsync(1) — no bash-completion.deb required

_pgsync() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD - 1]}"
    local opts='-h --help -V --version -q --quiet -v --verbose -n --dry-run --delete --schema-only --data-only --no-clean --single-transaction -s --source -t --target'

    case "$prev" in
        -s|--source|-t|--target)
            return
            ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
    fi
}

complete -F _pgsync pgsync pgsync.sh
