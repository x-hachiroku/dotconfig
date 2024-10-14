[[ ! -r '/home/chieri/.opam/opam-init/init.zsh' ]] || source '/home/chieri/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null

alias x11='GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb'

alias reset-plasma='kquitapp6 plasmashell || killall plasmashell; kstart plasmashell >/dev/null'
alias startplasma-wayland='export XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE KDE_SESSION_VERSION=6;
de /usr/lib/plasma-dbus-run-session-if-needed /usr/bin/startplasma-wayland'

if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    # alias y='wl-copy --trim-newline'
    # alias p='wl-paste -t text --no-newline'
    alias endsession='/usr/lib/qt6/bin/qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout; kquitapp6 plasmashell; killall startplasma-wayland'
else
    # alias y='xclip -selection c -r'
    # alias p='xclip -selection c -o'
    alias endsession='/usr/lib/qt6/bin/qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout; kquitapp6 plasmashell; killall startplasma-x11'
fi

function scan() {
    local i=0
    local dst
    while
        i=$((i+1)) && dst="scan${(l:2::0:)i}.pdf" && [[ -f $dst ]]
    do; true; done
    scanimage -d "airscan:escl:HP_Scanner:http://10.6.6.200:80/eSCL/" --format=tiff --resolution 300 --mode Color | magick - $dst
}

function packey-reset() {
    dirmngr </dev/null
    pacman-key --populate archlinux
    pacman-key --refresh-keys
}

function open {
    if [[ -e "$1" ]]; then
        xdg-open "$1"
    else
        return 233
    fi
}

function del {
    kioclient move "$@" 'trash:/'
}

function termbl() {
  local bl_dir=(/sys/class/backlight/*(N[1]))
  local max_brightness=$(<"${bl_dir}/max_brightness")
  local raw=$(( max_brightness * $1 / 10 ))

  echo "$raw" > "${bl_dir}/brightness"
}
