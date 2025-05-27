#!/usr/bin/env bash

# Removes embedded ass and ssa subs from video files.
# Takes 1 input (file path). To use recursevely use:
# find /path/to/media -type f -print0 | xargs -0 -P 4 -I {} ./remove_ass_ssa_subs.sh "{}"

input="$1"
ext="${input##*.}"
tmp_output="${input%.*}_nosubs.${ext}"

if [[ ! -f "$input" ]]; then
    echo "File not found: $input"
    exit 1
fi

subs_to_remove=$(ffprobe -v error \
                         -select_streams s \
                         -show_entries stream=index,codec_name \
                         -of default=noprint_wrappers=1 "$input" |
    awk '/^index=/ {idx=$0} /^codec_name=(ass|ssa)/ {print idx}' |
    cut -d= -f2)

if [[ -z "$subs_to_remove" ]]; then
    echo "No embedded .ass or .ssa subtitles found in $input"
    exit 0
fi

echo "Removing .ass/.ssa subtitle streams: $subs_to_remove"

map_args=(-map 0)
for sid in $subs_to_remove; do
    map_args+=("-map" "-0:$sid")
done

ffmpeg -i "$input" "${map_args[@]}" -c copy "$tmp_output"

if [[ -f "$tmp_output" ]]; then
    mv -f "$tmp_output" "$input"
    echo "Original file replaced: $input"
else
    echo "Failed to create output file."
    exit 1
fi
