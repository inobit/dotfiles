#!/bin/bash

set -e

echo "install mihomo"

# make sure you have set GPG_TTY
# Compress and encrypt
# tar -zcf - .mihomo | gpg -c -o mihomo.tar.gz.gpg
# Decrypt and decompress
# gpg -d mihomo.tar.gz.gpg | tar -zxf -

cdir=$(pwd)

mihomo_home="$HOME"/.mihomo

if [[ ! -d $mihomo_home ]]; then
	mkdir -p "$mihomo_home"
fi

cp ./config.yaml ./mihomo.service "$mihomo_home"

cd "$mihomo_home"

if [[ ! -f ./mihomo ]]; then
	echo "download mihomo"
	curl -fSsL -o mihomo.gz "https://github.com/MetaCubeX/mihomo/releases/download/v1.19.15/mihomo-linux-amd64-v2-v1.19.15.gz"
	gzip -d mihomo.gz
else
	chmod +x mihomo
	sudo ln -sf "$(pwd)"/mihomo /usr/local/bin/mihomo
fi

if [[ ! -f ./mihomosh ]]; then
	echo "download mihomosh"
	mihomosh_tmp=$(mktmp -d)
	curl -fsSL -o "$mihomosh_tmp"/mihomosh.tar.gz "https://github.com/SamuNatsu/mihomosh/releases/download/v2.0.0/mihomosh-Linux-musl-x86_64.tar.gz"
	tar -zxf "$mihomosh_tmp"/mihomosh.tar.gz -C "$mihomosh_tmp"
	mv "$mihomosh_tmp"/mihomosh .
	rm -rf "$mihomosh_tmp"
else
	chmod +x mihomosh
	ln -sf "$(pwd)"/mihomosh "$HOME"/.local/bin/mihomosh
	if ! grep -qE '^eval\s"\$\(mihomosh' "$HOME"/.zshrc; then
		printf '%s\n' 'eval "$(mihomosh shell-completion zsh)"' >>"$HOME"/.zshrc
	fi
	echo "mihomosh can be used to control mihomo. mihomosh should be config first, use command: mihomosh config edit -e nvim"
fi

echo "config mihomo"

[[ -d /etc/mihomo ]] || sudo mkdir -p /etc/mihomo

if [[ -d ./data ]]; then
	sudo cp -r ./data/* /etc/mihomo
fi

sudo ln -sf "$(pwd)"/config.yaml /etc/mihomo/config.yaml

sudo ln -sf "$(pwd)"/mihomo.service /etc/systemd/system/mihomo.service

sudo systemctl daemon-reload

sudo systemctl enable mihomo.service

echo "start mihomo"

sudo systemctl start mihomo.service

cd "$cdir"

echo "install mihomo done"
