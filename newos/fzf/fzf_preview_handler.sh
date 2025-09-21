#!/usr/bin/env bash

file_path=$1

if [[ -e "$file_path" ]]; then
	mime_type=$(file --mime-type -b "$file_path")

	case "$mime_type" in
	text/*)
		batcat --color=always --style=numbers --line-range=:500 "$file_path" || head --lines=500 "$file_path"
		;;
	inode/directory)
		ls -lh --color=always "$file_path"
		;;
	*)
		echo "$file_path"
		;;
	esac
else
	first_str=$(echo "$file_path" | awk '{print $2}')
	if command -v "$first_str" >/dev/null 2>&1; then
		whereis "$first_str"
	fi
fi
