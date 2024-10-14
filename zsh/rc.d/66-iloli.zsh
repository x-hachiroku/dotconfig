function _imgloli() {
    local failed=0
    function _loli() {
        local img="$1"
        local res bbcode
        res=$(curl -s \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: multipart/form-data" \
            -F "file=@${img}" \
            'https://img.ilolicon.com/api/v1/upload'
        )
        bbcode=$(echo "$res" | jq -r ".data.links.bbcode")
        if [[ $bbcode == "null" ]] || [[ $bbcode == "" ]]; then
            echo "$img $res"
            failed=233
        else
            echo "$bbcode"
        fi
    }

    find '.' -maxdepth 1 \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | sort \
        | env_parallel --env _loli --keep-order --linebuffer _loli {}

    unset -f _loli
    return $failed
}
