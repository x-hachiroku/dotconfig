if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <target_info_hash> <dir>"
    exit 1
fi

blocksizes="1M 2M 4M 8M 16M 512K 256K 128K 64K 32K 16K 32M 64M"
for blocksize in $blocksizes; do
    echo $"\nTesting $blocksize"
    transmission-create -s $blocksize -o "${2}-$blocksize.torrent" "$2"
    info_hash=$(transmission-show "${2}-$blocksize.torrent" | grep "Hash v1" | awk '{print $3}')
    if [ "$info_hash" = "$1" ]; then
        echo "Info hash matches!"
        return 0
    else
        echo "Info hash: $info_hash"
        rm "${2}-$blocksize.torrent"
    fi
done

return 233
