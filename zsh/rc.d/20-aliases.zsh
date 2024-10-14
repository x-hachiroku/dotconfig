export EDITOR=nvim
alias vi=$EDITOR
alias vim=$EDITOR

alias history='fc -l -i 1 | less +G'

alias tree='tree --dirsfirst --filelimit=32 -F'
alias lsblk='lsblk -o NAME,ID,LABEL,FSTYPE,FSSIZE,FSAVAIL,MOUNTPOINTS'
alias truecrypt='veracrypt -t'

alias pps='podman ps --all --format "table {{.ID}}\t{{.Status}}\t{{.Restarts}}\t{{.Names}}\t{{.PodName}}\t{{.Ports}}\t{{.Mounts}}"'

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

export UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3'
alias wget="wget -U '$UA' --content-disposition -e robots=off"
alias wclone='wget --mirror --convert-links --adjust-extension --page-requisites --no-parent'
alias curl="curl -A '$UA' --location"

alias convmv='convmv -r -t utf-8'

alias socks='ALL_PROXY=socks5://localhost:9000'

alias virsh='sudo virsh'
alias virt-viewer='sudo virt-viewer'

unalias scp 2>/dev/null
unalias rsync 2>/dev/null

function owsl() {
    realpath="$(readlink -f "$1")"
    cp "$realpath" ./tmp
    mv tmp "$1"
}

function pg() { ps -ef | grep -i "$@" | grep -v grep; }

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

function lsgrub() {
        sed ':again;$!N;$!b again; :b; s/{[^{}]*}//g; t b' /boot/grub/grub.cfg | cut -c -60 | grep -e "^menuentry" -e "submenu" | nl -v 0 | grep -e "menuentry" -e "submenu" --color
}

: <<'JS'
const encoder = new TextEncoder();
const keystr = prompt('Master Key:') + ' Ciallo~';
const keybuf = encoder.encode(keystr);
crypto.subtle.digest('SHA-256', keybuf).then(sha256 => {
    const b64 = btoa(String.fromCharCode(...new Uint8Array(sha256)));
    console.log(`Ay00-${b64.slice(0,4)}/${b64.slice(4, 8)}-${b64.slice(8, 12)}`.replaceAll('+', '-'));
});
JS
function getpwd() {
    if [ "$#" -ne 2 ]; then return 1; fi
    >&2 echo "Account: $2@$1"
    >&2 read "key?Master Key: "
    local b64=`echo -n "$@ $key Ciallo~" | openssl dgst -binary -sha256 | openssl base64 -A`
    echo Ay00-${b64:0:4}/${b64:4:4}-${b64:8:4} | sed 's/+/-/g'
    unset key
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
    $rdp /tls:seclevel:0 /timeout:60000 /size:1600x900 /sound /v:$@[-1] /d: ${=@[1,-2]}
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

function zipa() {
    local extra_args="$@[1,-2]"
    local src="$@[-1]"
    local archive=`basename "$src"`.zip
    noglob zip \
        $extra_args \
        --test \
        -9 `#compress level 9 (0-9)` \
        -X `#ignore extra file attrs` \
        -x */._* \
        -x */.DS_Store \
        -x */.DocumentRevisions-V100 \
        -x */.FBC* \
        -x */.Spotlight-V100 \
        -x */.TemporaryItems \
        -x */.VolumeIcon.icns \
        -x */.background \
        -x */.com.apple.timemachine.* \
        -x */.fseventsd \
        -x */.localized \
        -x */Icon \
        -x */\$RECYCLE.BIN* \
        -x */*~ \
        -x */.directory \
        -x */.fuse_hidden* \
        -x */.Trash* \
        -x */.nfs* \
        -x */'System Volume Information' \
        -r "$archive" "$src"
}

function unrar() {
    local dir=${1:t}
    mkdir -p "$dir"
    rar x "$1" "$dir"
}

function rara() {
    local extra_args="$@[1,-2]"
    local src="$@[-1]"
    local archive=`basename "$src"`.rar
    local RAR="
        -ep1     `# exclude base directory`
        -htb     `# use BLAKE2`
        -k       `# lock modification`
        -m5      `# compression level 5 (0-5)`
        -md256m  `# dictionary size 256M`
        -oi2     `# check identical files`
        -qo      `# add quick open information`
        -rr3p    `# recovery record 3%`
        -s       `# solid archive`
        -t       `# test`
    "
    RAR="${RAR//$'\n'/}" noglob rar a \
        ${=extra_args} \
        -x*/._* \
        -x*/.DS_Store \
        -x*/.DocumentRevisions-V100 \
        -x*/.FBC* \
        -x*/.Spotlight-V100 \
        -x*/.TemporaryItems \
        -x*/.VolumeIcon.icns \
        -x*/.background \
        -x*/.com.apple.timemachine.* \
        -x*/.fseventsd \
        -x*/.localized \
        -x*/Icon \
        -x*/\$RECYCLE.BIN* \
        -x*/*~ \
        -x*/.directory \
        -x*/.fuse_hidden* \
        -x*/.Trash* \
        -x*/.nfs* \
        -x*/'System Volume Information' \
        -r "$archive" "$src"
}

alias parara='env_parallel --env rara --jobs 1 --progress -u rara {}'

function _tg () {
    local -a tg file_opt img_opt
    zparseopts -D -E f=file_opt i=img_opt

    if [[ -n ${file_opt} ]]; then
        curl -Ss -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
            -F chat_id="$CHAT_ID" \
            -F document=@"$1"
    elif [[ -n ${img_opt} ]]; then
        curl -Ss -X POST \
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
        ffmpeg -an -i "$1" -c:a alac -c:v copy  copy \
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

alias hcheck='mkdir -p completed && find . -mindepth 2 -maxdepth 2 -name "galleryinfo.txt" -exec dirname {} \; | parallel --jobs 1 mv {} completed'

function garchive() {
    pbd=`basename "$PWD"`
    mkdir -p "$pbd"
    find . -mindepth 1 -maxdepth 1 -type d ! -name "$pbd" | parallel --jobs 2 --quote zip -0 --junk-paths --test -r "$pbd"/{}.cbz {}
}

function lsgid() {
    perl -e 'my @gids=(); foreach my $g (split("\n", `find .`)) {if ($g=~/\[(\d+)\](.cbz)?$/) {push @gids, $1}} print join(",", @gids);'
}
