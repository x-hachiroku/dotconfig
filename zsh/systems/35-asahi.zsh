alias which=where

function muvm() {
    if [[ $# -eq 0 ]]; then
        muvm zsh
    else
        /usr/bin/muvm \
            -it \
            --cpu-list 2-7 \
            --env VIRTUAL_ENV=muvm \
            -- \
            zsh -ic 'cd "$1"; shift; exec "$@"' muvm-zsh "$PWD" "$@"
    fi
}
