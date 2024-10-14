source env_parallel.zsh

alias endsession='/usr/lib/qt6/bin/qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout'
alias reset-plasma='kquitapp6 plasmashell || killall plasmashell; kstart plasmashell >/dev/null'

function open {
    if [[ -e "$1" ]]; then
        xdg-open "$1" >/dev/null 2>&1
    else
        return 233
    fi
}

function trash {
    kioclient move "$@" 'trash:/'
}

if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    alias y='wl-copy --trim-newline'
    alias p='wl-paste -t text --no-newline'
else
    alias y='xclip -selection c -r'
    alias p='xclip -selection c -o'
fi

function termbl () {
    sudo zsh -c "echo $(( $(cat /sys/class/backlight/*/max_brightness) * $1 / 100 )) > /sys/class/backlight/*/brightness"
}


if [[ $- =~ i ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_TTY" ]]; then
    tmux attach-session -t ssh 2>/dev/null || tmux new-session -s ssh "archey4; zsh"
fi
