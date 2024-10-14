source env_parallel.zsh

unalias y 2>/dev/null
unalias p 2>/dev/null
unalias scp 2>/dev/null
unalias rsync 2>/dev/null

bindkey -r '^[a'


export EDITOR=nvim
alias vi=$EDITOR
alias vim=$EDITOR

alias icat='kitty +kitten icat'

alias history='fc -l -i 1 | less +G'

alias ls='ls --color=auto --group-directories-first -X'
alias tree='tree --dirsfirst --filelimit=32 -F'
alias lsblk='lsblk -o NAME,MODEL,TYPE,LABEL,FSTYPE,FSSIZE,FSAVAIL,MOUNTPOINTS'
alias truecrypt='veracrypt -t'

alias pps='podman ps --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Restarts}}\t{{.Ports}}"'

alias py='ptpython'


_rsync_cmd='rsync --archive --hard-links --human-readable --one-file-system --partial-dir=rsync --info=progress2'

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

alias virsh='sudo virsh'
alias virt-manager='sudo virt-manager'
alias virt-viewer='sudo virt-viewer'

alias socks='ALL_PROXY=socks5://localhost:9000'


function pg() { ps -ef | grep -i "$@" | grep -v grep }

function ssg() { ss -ltnp | grep :$1 }

# tmux
function ssh() {
    if [ -n "$TMUX" ]; then
        tmux rename-window "${@: -1}"
        command ssh "$@"
        tmux set-window-option automatic-rename on
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

    function lsgrub() {
        sed ':again;$!N;$!b again; :b; s/{[^{}]*}//g; t b' /boot/grub/grub.cfg | cut -c -60 | grep -e "^menuentry" -e "submenu" | nl -v 0 | grep -e "menuentry" -e "submenu" --color
    }

function pdfmerge() { pdftk "$@" cat output merged.pdf }
function pdfrmpwd() { pdftk "$1" input_pw PROMPT output /tmp/unlocked && mv -f /tmp/unlocked "$1" }
function pdfrotate() {
    declare -A directions=( [u]=north [r]=east [d]=south [l]=west )
    local direction=$directions[$1]
    pdftk "$2" cat 1-end${direction} output /tmp/rotated.pdf && mv -f /tmp/rotated.pdf "$2"
}
function pdfcompress() {
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH \
        -dPDFSETTINGS=/ebook -sOutputFile="$2" "$1"
}

## Archives
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
    '*/Icon
'
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

function tgz() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local src="${argv[-1]}"
    local archive=`basename "$src"`.zip
    noglob tar \
        "${extra_args[@]}" \
        -czv \
        -f "$archive" "$src"
}

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
    local -a gallery
    zparseopts -D -E g=gallery
    local -a extra_args=("${(@)argv[1,-2]}")
    local src="${argv[-1]}"
    local -a args=(
        -htb  `# use BLAKE2`
        -k    `# lock modification`
        -oi2  `# check identical files`
        -qo   `# add quick open information`
        -rr3p `# recovery record 3%`
        -t    `# test after archiving`
    )
    if [[ -n $gallery ]]; then
        args+=(
            -ep `# exclude paths`
            -m0 `# store only`
        )
        local archive=`basename "$src"`.cbr
    else
        args+=(
            -ep1 `# exclude base directory`
            -s   `# solid archive`
            -m5  `# compression level 5 (0-5)`
            -md512m `# dictionary size 512MB`
        )
        local archive=`basename "$src"`.rar
    fi
    noglob rar a \
        "${args[@]}" \
        "${extra_args[@]}" \
        "${_rar_ignore_args[@]}" \
        "$archive" "$src"
}

function tgx() {
    local -a inplace
    zparseopts -D -E i=inplace
    local -a extra_args=("${(@)argv[1,-2]}")
    local archive="${argv[-1]}"
    if [[ -n $gallery ]]; then
        local dst=`basename "${archive:r}"`
    else
        local dst="${archive:r}"
    fi
    mkdir -p "$dst"
    noglob tar \
        -C "$dst" \
        "${extra_args[@]}" \
        -xzvf "$archive" \
        && rm -i "$archive"
}

function zipx() {
    local -a inplace
    zparseopts -D -E i=inplace
    local -a extra_args=("${(@)argv[1,-2]}")
    local archive="${argv[-1]}"
    if [[ -n $gallery ]]; then
        local dst=`basename "${archive:r}"`
    else
        local dst="${archive:r}"
    fi
    mkdir -p "$dst"
    noglob unzip \
        "${extra_args[@]}" \
        -d "$dst" \
        "$archive" \
        -x "${_archive_ignore_list[@]}" \
        && rm -i "$archive"
}

function rarx() {
    local -a inplace
    zparseopts -D -E i=inplace
    local -a extra_args=("${(@)argv[1,-2]}")
    local archive="${argv[-1]}"
    if [[ -n $gallery ]]; then
        local dst=`basename "${archive:r}"`
    else
        local dst="${archive:r}"
    fi
    mkdir -p "$dst"
    noglob rar x \
        "${extra_args[@]}" \
        "${_rar_ignore_args[@]}" \
        "$archive" "$dst" \
        && rm -i "$archive"
}

function 7zx() {
    local -a inplace
    zparseopts -D -E i=inplace
    local -a extra_args=("${(@)argv[1,-2]}")
    local archive="${argv[-1]}"
    if [[ -n $gallery ]]; then
        local dst=`basename "${archive:r}"`
    else
        local dst="${archive:r}"
    fi
    mkdir -p "$dst"
    local _7z=7z
    if 7z l -p'' "$archive" | grep -i '04F71101' &>/dev/null; then
        _7z=7zz
    fi
    noglob $_7z x \
        "${extra_args[@]}" \
        "${_7z_ignore_args[@]}" \
        "$archive" -o"$dst" \
        && rm -i "$archive"
}

alias parara='env_parallel --env rara --env _rar_ignore_args --jobs 2 --progress -u rara {}'
alias pararag='env_parallel --env rara --env _rar_ignore_args --jobs 1 --progress -u rara -g {}'

function ep() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local cmd="${argv[-1]}"
    local cmd='for rc in $HOME/.config/zsh/rc.d/*.zsh; do source $rc @>/dev/null; done;'"$cmd"
    parallel -q "$extra_args[@]" zsh -c "$cmd" zsh {}
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

function ffcheck() {
    ffmpeg -v error -i $1 -f null -
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
        ffmpeg -i "$1" -c:a alac -c:a jpg -c copy "${1%.*}.m4a"
    elif [ $# -eq 2 ]; then
        ffmpeg -i "$1" -i "$2" -c:a alac -c:v copy \
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
