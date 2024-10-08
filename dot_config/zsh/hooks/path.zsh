typeset -gU PATH path
typeset -gU FPATH fpath

setopt hist_ignore_dups

path=(
    '/usr/local/bin'(N-/)
    '/usr/local/go/bin'(N-/)
    '/usr/bin'(N-/)
    '/bin'(N-/)
    '/usr/local/sbin'(N-/)
    '/usr/sbin'(N-/)
    '/sbin'(N-/)
)

path=(
    "$HOME/.local/bin"(N-/)
    "$GOBIN"(N-/)
    "$HOME/bin"(N-/)
    "$path[@]"
)
