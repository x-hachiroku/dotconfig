function 9zx() {
    7zx \
        -p⑨ \
        '-xr!*御所*.jpg' \
        '-xr!谨防被骗*.jpg' \
        '-xr!NO DATA….jpg' \
        '-xr!*御所*.jpeg' \
        '-xr!谨防被骗*.jpeg' \
        '-xr!NO DATA….jpeg' \
        '-xr!*御所*.png' \
        '-xr!谨防被骗*.png' \
        '-xr!NO DATA….png' \
        "${argv[@]:1}"
}

function 9rx() {
    rarx \
        -p⑨ \
        '-x*/*御所*.jpg' \
        '-x*/谨防被骗*.jpg' \
        '-x*/NO DATA….jpg' \
        '-x*/*御所*.jpeg' \
        '-x*/谨防被骗*.jpeg' \
        '-x*/NO DATA….jpeg' \
        '-x*/*御所*.png' \
        '-x*/谨防被骗*.png' \
        '-x*/NO DATA….png' \
        "${argv[@]:1}"
}

function 9ra() {
    rara \
        -p⑨      `# password`
        -v1920m  `# volume size 1920 megabytes`
        "${argv[@]:1}"
}

alias p9ra='env_parallel --env 9ra --jobs 2 --progress -u 9ra {}'


function ygo() {
    curl -sS -G 'https://ygocdb.com/' --data-urlencode "search=$1" | pup 'h3:nth-child(4) > span:first-child text{}'
}
