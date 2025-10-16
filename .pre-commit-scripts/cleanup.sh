#!/usr/bin/env bash

set -e

for file in "$@"; do
	if [[ "$file" == "mihomo/config.yaml" ]]; then

		sed -i -E -e 's/^(secret:\s*).*/\1<secret>/' -e '/^proxy-providers/{n;s/^(\s*)\S+.*/\1<subscription name>:/;n;n;s/^(\s*url:\s*).*/\1<subscription url>/;n;s/^(\s*path:\s*.*\/).*/\1<subscription name>.yaml/}' "$file"
		git add "$file"
		echo "$file has been cleaned"
	fi
done
