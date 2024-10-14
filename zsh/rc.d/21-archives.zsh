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

function tgz() {
    local -a extra_args=("${(@)argv[1,-2]}")
    local src="${argv[-1]}"
    local archive=`basename "$src"`.tar.gz
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
    if [[ -n $inplace ]]; then
        local dst="${archive:r}"
    else
        local dst=`basename "${archive:r}"`
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
    if [[ -n $inplace ]]; then
        local dst="${archive:r}"
    else
        local dst=`basename "${archive:r}"`
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
    if [[ -n $inplace ]]; then
        local dst="${archive:r}"
    else
        local dst=`basename "${archive:r}"`
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
    if [[ -n $inplace ]]; then
        local dst="${archive:r}"
    else
        local dst=`basename "${archive:r}"`
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
