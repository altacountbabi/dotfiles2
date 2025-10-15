stripSlash() {
    res="$1"
    if test "${res:0:1}" = /; then res=${res:1}; fi
}

escapeEquals() {
    echo "$1" | sed -e 's/\\/\\\\/g' -e 's/=/\\=/g'
}

addPath() {
    target="$1"
    source="$2"
    echo "$(escapeEquals "$target")=$(escapeEquals "$source")" >> pathlist
}

stripSlash "$efiBootImage"; efiBootImage="$res"

efiBootFlags="-eltorito-alt-boot
              -e $efiBootImage
              -no-emul-boot
              -isohybrid-gpt-basdat"

touch pathlist

for ((i = 0; i < ${#targets[@]}; i++)); do
    stripSlash "${targets[$i]}"
    addPath "$res" "${sources[$i]}"
done

for i in $(< $closureInfo/store-paths); do
    addPath "${i:1}" "$i"
done

if [[ -n "$squashfsCommand" ]]; then
    (out="nix-store.squashfs" eval "$squashfsCommand")
    addPath "nix-store.squashfs" "nix-store.squashfs"
fi

if [[ ${#objects[*]} != 0 ]]; then
    cp $closureInfo/registration nix-path-registration
    addPath "nix-path-registration" "nix-path-registration"
fi

for ((n = 0; n < ${#objects[*]}; n++)); do
    object=${objects[$n]}
    symlink=${symlinks[$n]}
    if test "$symlink" != "none"; then
        mkdir -p $(dirname ./$symlink)
        ln -s $object ./$symlink
        addPath "$symlink" "./$symlink"
    fi
done

xorriso="xorriso
 -boot_image any gpt_disk_guid=$(uuid -v 5 daed2280-b91e-42c0-aed6-82c825ca41f3 $out | tr -d -)
 -volume_date all_file_dates =$SOURCE_DATE_EPOCH
 -as mkisofs
 -iso-level 3
 -volid ${volumeID}
 -appid nixos
 -publisher nixos
 -graft-points
 -full-iso9660-filenames
 -joliet
 ${efiBootFlags}
 -r
 -path-list pathlist
 --sort-weight 0 /
"

mkdir -p $out

$xorriso -output $out/$isoName

if test -n "$compressImage"; then
    echo "Compressing image..."
    zstd -T$NIX_BUILD_CORES --rm "$out/$isoName"
fi
