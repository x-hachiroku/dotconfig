source env_parallel.zsh

unalias y 2>/dev/null
unalias p 2>/dev/null
unalias scp 2>/dev/null
unalias rsync 2>/dev/null

bindkey -s '^[[27;1u' '^[' # kitty esc
bindkey '^[^M' accept-line # alt+enter


export EDITOR=nvim
export VISUAL=$EDITOR
alias vi=$EDITOR
alias vim=$EDITOR

alias rmeol="sed -i -z 's/\n*$//'"
alias oneeol="sed -i -z 's/\n*$/\n/'"
alias rmbom="sed -i -z $'s/^\uFEFF//'"

alias icat='kitty +kitten icat'
alias qre='qrencode -o >(kitten icat)'

alias history='fc -l -i 1 | less +G'

alias ls='ls --color=auto --group-directories-first -X'
alias tree='tree --dirsfirst --filelimit=32 -F'
alias lsblk='lsblk -o NAME,MODEL,TYPE,LABEL,FSTYPE,FSSIZE,FSAVAIL,MOUNTPOINTS'
alias convmv='convmv -r -t utf-8'
alias truecrypt='veracrypt -t'

alias py='ptpython'

alias pps='podman ps --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Restarts}}\t{{.Ports}}"'

_UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3'
alias socks='ALL_PROXY=socks5://localhost:9000'
alias wget="wget -U '$_UA' --content-disposition -e robots=off"
alias wclone='wget --mirror --convert-links --adjust-extension --page-requisites --no-parent'
alias curl="curl -A '$_UA' --location"

_rsync_cmd='rsync --archive --hard-links --human-readable --one-file-system --partial-dir=rsync --info=progress2'

# if is-darwin && grep -q 'file-flags' <(rsync --help 2>&1); then
#     _rsync_cmd="${_rsync_cmd} --crtimes --fileflags --force-change"
# fi

alias rsync-copy="${_rsync_cmd}"
alias rsync-move="${_rsync_cmd} --remove-source-files"
alias rsync-update="${_rsync_cmd} --update"
alias rsync-sync="${_rsync_cmd} --update --delete"
unset _rsync_cmd

alias virsh='sudo virsh'
alias virt-manager='sudo virt-manager'
alias virt-viewer='sudo virt-viewer'

function pg() { ps -ef | grep -i "$@" | grep -v grep }
function ssg() { ss -ltnp | grep :$1 }

function ep() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local cmd="${argv[-1]}"
    parallel -q "$extra_args[@]" env NO_TMUX=1 zsh -c "$cmd" zsh {}
}


function conda() {
    __conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
        if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/opt/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="/opt/miniconda3/bin:$PATH"
        fi
    else
        echo "conda not found"
        return 1
    fi
    unset __conda_setup

    conda $@
}


function pdfrmpwd() { pdftk "$1" input_pw PROMPT output /tmp/unlocked && mv -f /tmp/unlocked "$1" }
function pdfrotate() {
    local -A directions=( [n]=north [e]=east [s]=south [w]=west )
    local direction=$directions[$1]
    pdftk "$2" cat 1-end${direction} output /tmp/rotated.pdf && mv -f /tmp/rotated.pdf "$2"
}
function pdfcompress() {
    gs \
        -q \
        -dNOPAUSE \
        -dBATCH \
        -dSAFER \
        -sDEVICE=pdfwrite \
        -dCompatibilityLevel=1.4 \
        -dPDFSETTINGS=/screen \
        -dEmbedAllFonts=true \
        -dSubsetFonts=true \
        -dColorImageDownsampleType=/Bicubic \
        -dColorImageResolution=144 \
        -dGrayImageDownsampleType=/Bicubic \
        -dGrayImageResolution=144 \
        -dMonoImageDownsampleType=/Bicubic \
        -dMonoImageResolution=144 \
        -sOutputFile=$1_compressed.pdf \
        $1; \
}

# tmux

function ssh() {
    if [ -n "$TMUX" ]; then
        tmux rename-window "${@: -1}"
        command ssh "$@"
        local ret=$?
        tmux set-window-option automatic-rename on
        return $ret
    else
        command ssh "$@"
    fi
}

function de() {
    if [[ $# -eq 0 ]]; then
        return 1
    fi
    if [[ -v TMUX ]]; then
        tmux detach -E "exec $*"
    else
        exec "$@"
    fi
}

function y() {
    local req
    req=$(base64 | tr -d '\n')
    printf '\e]52;c;%s\e\\' "$req"
}
function p() {
    ## only for tmux < 3.7
    # if [[ -v TMUX ]]; then
    #     tmux refresh-client -l "$TMUX_PANE" || return 1
    # else
    printf '\e]52;c;?\e\\' >&2
    # fi
    IFS= read -r -s -t 0.5 -d '\' res || return 1
    res=${res%$'\e'}
    printf '%s' "${res##*;}" | base64 -d
}

alias pvi='vi =(p)'

# vm

function conn-qcow2() {
    sudo modprobe nbd nbds_max=1
    sudo qemu-nbd --aio=io_uring --discard=unmap -c /dev/nbd0 "$1"
}

function disconn-qcow2() {
    sudo qemu-nbd -d /dev/nbd0
    sudo modprobe -r nbd
}

function mrdp() {
    local rdp=sdl-freerdp3
    # if [ $XDG_SESSION_TYPE = "wayland" ]; then rdp=sdl-freerdp3; fi
    $rdp /sec:tls:off /timeout:60000 /size:1280x720 /smart-sizing /sound +clipboard /v:$@[-1] /d: ${=@[1,-2]}
}

# av

function ffcheck() {
    local err
    err=$(ffmpeg -nostdin -v error -xerror -i "$1" -f null - 2>&1)
    [[ -z $err ]] || printf '%s\n===\n%s\n\n' "$1" "$err"
}

function to_webp() {
    ffmpeg \
        -ss $2 -t $3 \
        -i "$1" \
        -vcodec libwebp \
        -vf "scale=1080:-2" \
        -loop 0 \
        -q:v 70 \
        -pix_fmt yuv420p \
        -compression_level 6 \
        "$4"
}

function to_alac() {
    if [ $# -eq 1 ]; then
        ffmpeg -i "$1" -c:a alac -c:v jpg "${1%.*}.m4a"
    elif [ $# -eq 2 ]; then
        ffmpeg -i "$1" -i "$2" -c:a alac -c:v jpg \
            -disposition:v attached_pic -metadata:s:v:0 "comment=Cover (front)" "${1%.*}.m4a"
    else
        >&2 echo "Usage: to_alac <input> [cover]"
        return 1
    fi
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

function imgcam() {
    sudo modprobe v4l2loopback devices=1 video_nr=99 card_label="USB Camera" exclusive_caps=1
    ffmpeg -loop 1 -re -framerate 30 -i $1 -vf 'scale=1280:720:force_original_aspect_ratio=decrease,format=yuv420p,pad=1280:720:(ow-iw)/2:(oh-ih)/2:color=white' -f v4l2 /dev/video99
    while ! sudo modprobe -r v4l2loopback 2>/dev/null; do; sleep 1; done
}

# misc

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
    extension=${extension:l}
    if [[ $extension == "jpeg" ]]; then extension=jpg; fi

    local date sha newname
    date=$(date +"%Y%m%d" -u -r "$1")
    newname="$(dirname "$1")/[${date}] $(basename $1)"

    if [[ $1 == $newname ]]; then
        return
    else
        mv -i "$1" "$newname"
    fi
}

function zfill() {
    if [[ $# -ne 1 || ! -d "$1" ]]; then
        return 233
    fi
    subdirs=("$1"/*(N/))
    if [[ ${#subdirs[@]} -gt 0 ]]; then
        echo "Target contains subdirectories" >&2
        return 233
    fi

    files=("$1"/*(N.n))
    count=0
    for filepath in "${files[@]}"; do
        filename="${filepath:t}"
        newname=$(printf "%04d-%s" $count "$filename")
        mv -n "$filepath" "$1/$newname"
        ((count++))
    done
}

function stripdir() {
    for d in *(/N); do
        local contents=( "$d"/*(ND) )
        if (( ${#contents[@]} == 1 )) && [[ -d "${contents[1]}" ]]; then
            local sub="${d}/.tmp_${RANDOM}"
            mv "${contents[1]}" "$sub"
            mv "$sub"/*(ND) "$d"/
            rmdir "$sub"
        fi
    done
}
