function rar() {
    podman run -it --rm -v ./:/data --arch amd64 localhost/rar /lib64/ld-linux-x86-64.so.2 /rar/rar "$@"
}

function unrar() {
    podman run -it --rm -v ./:/data --arch amd64 localhost/rar /lib64/ld-linux-x86-64.so.2 /rar/unrar "$@"
}

function rara() {
    podman run -it --rm -v ./:/data --arch amd64 localhost/rar /rar/rara.bash "$@"
}
