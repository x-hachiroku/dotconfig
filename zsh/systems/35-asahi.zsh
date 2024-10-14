alias which=where

function mmux() {
    if [ -v TMUX ]; then
        local _TMUX="$TMUX"
        unset TMUX
    fi

    muvm --cpu-list 2-7 --env VIRTUAL_ENV=muvm -- tmux -L muvm new-session -s muvm -c "$PWD"

    if [ -v _TMUX ]; then
        export TMUX="$_TMUX"
    fi
}
