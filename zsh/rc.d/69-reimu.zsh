function 9ra() {
    rara \
        -p⑨      `# password`
        -v1920m  `# volume size 1920 megabytes`
        "${argv[@]:1}"
}

_9_ignore_list=(
    '*御所*.png'
    '*御所*.jpg'
    '*御所*.jpeg'
    '谨防被骗*.png'
    '谨防被骗*.jpg'
    '谨防被骗*.jpeg'
    'NO DATA….png'
    'NO DATA….jpg'
    'NO DATA….jpeg'
)

function 9zx() {
    local -a _ignore_args
    for pattern in "${_9_ignore_list[@]}"; do
        _ignore_args+=("-xr!$pattern")
    done

    7zx -p⑨ \
        "${_ignore_args[@]}" \
        "${argv[@]:1}"
}

function 9rx() {
    local -a _ignore_args
    for pattern in "${_9_ignore_list[@]}"; do
        _ignore_args+=("-x$pattern")
    done

    rarx -p⑨ \
        "${_ignore_args[@]}" \
        "${argv[@]:1}"
}

function ygo() {
    curl -sS -G 'https://ygocdb.com/' --data-urlencode "search=$1" | pup 'h3:nth-child(4) > span:first-child text{}'
}
