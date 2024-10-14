alias x11='GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb'

source env_parallel.zsh

function open {
    if [[ -e "$1" ]]; then
        xdg-open "$1" >/dev/null 2>&1
    else
        return 233
    fi
}

if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    alias y='wl-copy --trim-newline'
    alias p='wl-paste -t text --no-newline'
    alias endsession='kquitapp6 plasmashell; killall startplasma-wayland ;/usr/lib/qt6/bin/qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout'
else
    alias y='xclip -selection c -r'
    alias p='xclip -selection c -o'
    alias endsession='kquitapp6 plasmashell; killall startplasma-x11 ;/usr/lib/qt6/bin/qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout'
fi

alias reset-plasma='kquitapp6 plasmashell || killall plasmashell; kstart plasmashell >/dev/null'
alias startplasma-wayland='/usr/lib/plasma-dbus-run-session-if-needed /usr/bin/startplasma-wayland'


function del {
    kioclient move "$@" 'trash:/'
}


function tbr () {
    sudo zsh -c "echo $(( $(cat /sys/class/backlight/*/max_brightness) * $1 / 100 )) > /sys/class/backlight/*/brightness"
}
