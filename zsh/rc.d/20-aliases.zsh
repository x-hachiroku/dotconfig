unalias scp 2>/dev/null
unalias rsync 2>/dev/null

export EDITOR=nvim
alias vi=$EDITOR
alias vim=$EDITOR

alias history='fc -l -i 1 | less +G'

alias ls='ls --color=auto --group-directories-first -X'
alias tree='tree --dirsfirst --filelimit=32 -F'
alias lsblk='lsblk -o NAME,MODEL,TYPE,LABEL,FSTYPE,FSSIZE,FSAVAIL,MOUNTPOINTS'
alias truecrypt='veracrypt -t'

alias pps='podman ps --all --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.PodName}}\t{{.Status}}\t{{.Restarts}}\t{{.Ports}}"'

alias py='ptpython'

_rsync_cmd='rsync --archive --compress --hard-links --human-readable --one-file-system --partial-dir=rsync --progress --verbose'

# if is-darwin && grep -q 'file-flags' <(rsync --help 2>&1); then
#     _rsync_cmd="${_rsync_cmd} --crtimes --fileflags --force-change"
# fi

alias rsync-copy="${_rsync_cmd}"
alias rsync-move="${_rsync_cmd} --remove-source-files"
alias rsync-update="${_rsync_cmd} --update"
alias rsync-sync="${_rsync_cmd} --update --delete"
unset _rsync_cmd

alias rmeol="sed -i -z 's/\n*$//'"
alias oneeol="sed -i -z 's/\n*$/\n/'"
alias rmbom="sed -i -z $'s/^\uFEFF//'"

_UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3'
alias wget="wget -U '$_UA' --content-disposition -e robots=off"
alias wclone='wget --mirror --convert-links --adjust-extension --page-requisites --no-parent'
alias curl="curl -A '$_UA' --location"

alias convmv='convmv -r -t utf-8'

alias socks='ALL_PROXY=socks5://localhost:9000'

alias virsh='sudo virsh'
alias virt-manager='sudo virt-manager'
alias virt-viewer='sudo virt-viewer'

function conda() {
    __conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/opt/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="/opt/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup

    conda $@
}

function pg() { ps -ef | grep -i "$@" | grep -v grep }

function ep() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local cmd="${argv[-1]}"
    cmd='for rc in $HOME/.config/zsh/rc.d/*.zsh; do source $rc @>/dev/null; done;'"$cmd"
    cat | parallel -q "$extra_args[@]" zsh -c "$cmd" zsh {}
}

function lsgrub() {
        sed ':again;$!N;$!b again; :b; s/{[^{}]*}//g; t b' /boot/grub/grub.cfg | cut -c -60 | grep -e "^menuentry" -e "submenu" | nl -v 0 | grep -e "menuentry" -e "submenu" --color
}

function shaname() {
    local dir=$(dirname "$1")
    local extension="${1##*.}"

    extension=${extension:l}
    if [[ $extension == "jpeg" ]]; then extension=jpg; fi

    local sha=`shasum -a 256 "$1"`
    local newname="$dir/${sha:0:16}.${extension:l}"

    if [[ $1 -ef $newname ]]; then return; fi
    mv -f "$1" "$newname"
}

function datename() {
    local dir=$(dirname "$1")
    local extension="${1##*.}"

    extension=${extension:l}
    if [[ $extension == "jpeg" ]]; then extension=jpg; fi

    local date=$(date +"%Y%m%d%H%M%S" -u -r "$1")
    local sha=`shasum -a 256 "$1"`
    newname="$dir/${date}-${sha:0:16}.${extension:l}"

    if [[ $1 == $newname ]]; then
        return
    else
        mv -f "$1" "$newname" 2> /dev/null || true
        rm "$1" 2> /dev/null || true
    fi
}

function _tg () {
    local -a tg file_opt img_opt
    zparseopts -D -E f=file_opt i=img_opt

    if [[ -n ${file_opt} ]]; then
        curl -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
            -F chat_id="$CHAT_ID" \
            -F document=@"$1"
    elif [[ -n ${img_opt} ]]; then
        curl -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto" \
            -F chat_id="$CHAT_ID" \
            -F photo=@"$1"
    else
        curl -Ss -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d parse_mode='HTML' \
            -d text="$*"
    fi
}

function conn-qcow2() {
    sudo modprobe nbd nbds_max=1
    sudo qemu-nbd --aio=io_uring --discard=unmap -c /dev/nbd0 "$1"
}

function disconn-qcow2() {
    sudo qemu-nbd -d /dev/nbd0
    sudo modprobe -r nbd
}

function mrdp() {
    local rdp=xfreerdp3
    # if [ $XDG_SESSION_TYPE = "wayland" ]; then rdp=sdl-freerdp3; fi
    $rdp /sec:tls:off /timeout:60000 /size:1280x720 /smart-sizing /sound +clipboard /v:$@[-1] /d: ${=@[1,-2]}
}

function pdf-pages() { pdftk "$1" dump_data | grep NumberOfPages }
function pdf-merge() { pdftk "$@" cat output merged.pdf }
function pdf-rmpwd() { pdftk "$1" input_pw PROMPT output /tmp/unlocked && mv -f /tmp/unlocked "$1" }
function pdf-rotate() {
    declare -A directions=( [u]=north [r]=east [d]=south [l]=west )
    local direction=$directions[$1]
    pdftk "$2" cat 1-end${direction} output /tmp/rotated.pdf && mv -f /tmp/rotated.pdf "$2"
}
function pdf-compress() {
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH \
        -dPDFSETTINGS=/ebook -sOutputFile="$2" "$1"
}

function getpwd() {
    if [ "$#" -ne 2 ]; then return 1; fi
    >&2 echo "Account: $2@$1"
    >&2 read "key?Master Key: "
    local b64=`echo -n "$@ $key Ciallo~" | openssl dgst -binary -sha256 | openssl base64 -A`
    echo Ay00-${b64:0:4}/${b64:4:4}-${b64:8:4} | sed 's/+/-/g'
    unset key
}

_archive_ignore_list=(
    '*/desktop.ini'
    '*/thumbs.db'
    '*/__MACOSX*'
    '*/._*'
    '*/.DS_Store'
    '*/.DocumentRevisions-V100'
    '*/.FBC*'
    '*/.Spotlight-V100'
    '*/.TemporaryItems'
    '*/.VolumeIcon.icns'
    '*/.background'
    '*/.com.apple.timemachine.*'
    '*/.fseventsd'
    '*/.localized'
    '*/Icon'
    '*/\$RECYCLE.BIN*'
    '*/*~'
    '*/.directory'
    '*/.fuse_hidden*'
    '*/.Trash*'
    '*/.nfs*'
    '*/"System Volume Information"'
)

typeset -a _rar_ignore_args _7z_ignore_args
for pattern in "${_archive_ignore_list[@]}"; do
    _rar_ignore_args+=("-x$pattern")
    _7z_ignore_args+=("-xr!$pattern")
done

function zipa() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local src="${argv[-1]}"
    local archive=`basename "$src"`.zip
    noglob zip \
        --test \
        -9 `#compress level 9 (0-9)` \
        -X `#ignore extra file attrs` \
        "${extra_args[@]}" \
        -x "${_archive_ignore_list[@]}" \
        -r "$archive" "$src"
}

function rara() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local src="${argv[-1]}"
    local archive=`basename "$src"`.rar
    local -a _RAR=(
        -ep1     `# exclude base directory`
        -htb     `# use BLAKE2`
        -k       `# lock modification`
        -m5      `# compression level 5 (0-5)`
        -md512m  `# dictionary size 512MB`
        -oi2     `# check identical files`
        -qo      `# add quick open information`
        -rr3p    `# recovery record 3%`
        -s       `# solid archive`
        -t       `# test after archiving`
    )
    RAR="${_RAR[@]}" noglob rar a \
        "${extra_args[@]}" \
        "${_rar_ignore_args[@]}" \
        "$archive" "$src"
}

alias parara='env_parallel --env rara --env _rar_ignore_args --jobs 2 --progress -u rara {}'

function zipx() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local archive="${argv[-1]}"
    local dst="$(basename ${archive:r})"
    noglob unzip \
        "${extra_args[@]}" \
        -d "$dst" \
        "$archive" \
        -x "${_archive_ignore_list[@]}"
}

function rarx() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local archive="${argv[-1]}"
    local dst="$(basename ${archive:r})"
    mkdir -p "$dst"
    rar x \
        "${extra_args[@]}" \
        "${_rar_ignore_args[@]}" \
        "$archive" "$dst" \
        && rm "$archive"
}

function 7zx() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local archive="${argv[-1]}"
    local dst="$(basename ${archive:r})"
    local _7z=7z
    if 7z l -p'' "$archive" | grep -i '04F71101' &>/dev/null; then
        _7z=7zz
    fi
    $_7z x \
        "${extra_args[@]}" \
        "${_7z_ignore_args[@]}" \
        "$archive" -o"$dst" \
        && rm "$archive"
}

function iwrap() {
    local img=$1
    shift
    for f in $@; do
        cat $img "$f" >> "$f.jpg"
    done
}

function group_albums() {
    find . -mindepth 1 -maxdepth 1 -type f \( -name *.flac -o -name *.m4a \) -print0 | while read -d $'\0' audio; do
        album="`ffprobe $audio 2>&1 | grep -i 'album ' | tr -s ' ' | cut -d ' ' -f 4-`"
        mkdir -p "$album"
        mv "$audio" "$album"
    done
}

function spcue() {
    cue="$1"
    aud="$2"
    disc="$3"
    if [ -z "$cue" ]; then
        cue=`find . -maxdepth 1 -name '*.cue' -print -quit`
    fi
    if [ -z "$aud" ]; then
        aud=`find . -maxdepth 1 \( -name '*.wav' -o -name '*.flac' -o -name '*.tak' -o -name '*.tta' -o -name '*.ape' \) -print -quit`
    fi

    rmbom "$cue"
    shnsplit -f "$cue" -o flac -t "${3:-1}-%n %t" "$aud"
    if [[ $? -eq 0 ]]; then rm "$aud"
    else return 1; fi
    cuetag.sh "$cue" *.flac
}

function to_webp() {
    ffmpeg -i "$1" \
        -loop 0 \
        -lossless 0 \
        -s 1080:720 \
        -q:v 90 \
        -compression_level 6 \
        -ss $2 -to $3 \
        "$4"
}

function to_alac() {
    if [ $# -eq 1 ]; then
        ffmpeg -i "$1" -c:a alac -c:a jpg -c copy "${1%.*}.m4a"
    elif [ $# -eq 2 ]; then
        ffmpeg -i "$1" -i "$2" -c:a alac -c:v copy \
            -disposition:v attached_pic -metadata:s:v:0 "comment=Cover (front)" "${1%.*}.m4a"
    else
        >&2 echo "Usage: to_alac <input> [cover]"
        return 1
    fi
}

function stripdir() {
    find . -mindepth 2 -maxdepth 2 -type d -exec bash -c 'mv -i "$1"/* "$1"/.. && rmdir "$1"' stripdir {} \;
}

function zfill() {
    ls | while read -r f; do mv -i "$f" `printf "%04d" ${f%.*}`.${f##*.}; done
}
