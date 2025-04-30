#!/bin/bash

rootPath=$1
tempRoot="/data/downloads/torrent/temporary"

find "$rootPath" -iname '*.rar' -execdir bash -c '
sourcePath="$1"
tempRoot="$2"

tmpTargetPath=$(mktemp --directory --tmpdir="$tempRoot")
echo "Processing $sourcePath into $tmpTargetPath"

unrar x -o- "$sourcePath" "$tmpTargetPath"

shopt -s dotglob nullglob
mv "$tmpTargetPath"/* ./
shopt -u dotglob nullglob

rm -r "$tmpTargetPath"
' bash {} "$tempRoot" \;
