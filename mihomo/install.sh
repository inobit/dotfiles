#!/bin/bash

set -e

echo "install mihomo"

# make sure you have set GPG_TTY
# Compress and encrypt
# tar -zcf - .mihomo | gpg -c -o mihomo.tar.gz.gpg
# Decrypt and decompress
# gpg -d mihomo.tar.gz.gpg | tar -zxf -

read -r -p "input proxy address: " proxy
if [[ -z $proxy ]]; then
	client=$(echo "$SSH_CLIENT" | awk '{print $1}')
	if [[ -n $client ]]; then
		echo "Trying to use clinet's proxy"
		if timeout 3 telnet "$client" 7890 >/dev/null 2>&1; then
			proxy="http://$client:7890"
		fi
	fi
fi
if [[ -n $proxy ]]; then
	export ALL_PROXY=$proxy
	export NO_PROXY="127.0.0.1,localhost,::1"
	echo "proxy set to $proxy"
else
	echo "proxy need to be set"
	exit 1
fi

# config timezone
if [[ $(date +%z) != +0800 ]]; then
	which timedatectl 1>/dev/null 2>&1 && sudo timedatectl set-timezone Asia/Shanghai
fi

cdir=$(pwd)

mihomo_home="$HOME"/.mihomo

if [[ ! -d $mihomo_home ]]; then
	mkdir -p "$mihomo_home"
fi

if [[ ! -f $mihomo_home/config.yaml ]]; then
	cp ./config.yaml "$mihomo_home"
fi

if [[ ! -f $mihomo_home/mihomo.service ]]; then
	cp ./mihomo.service "$mihomo_home"
fi

cd "$mihomo_home"

install_mihomo() {
	chmod +x mihomo
	sudo ln -sf "$(pwd)"/mihomo /usr/local/bin/mihomo
}

if [[ ! -f ./mihomo ]]; then
	echo "download mihomo"
	curl -fSsL -o mihomo.gz "https://github.com/MetaCubeX/mihomo/releases/download/v1.19.15/mihomo-linux-amd64-v2-v1.19.15.gz"
	gzip -d mihomo.gz
	install_mihomo
else
	install_mihomo
fi

install_mihomosh() {
	chmod +x mihomosh
	test -d "$HOME"/.local/bin || mkdir -p "$HOME"/.local/bin
	ln -sf "$(pwd)"/mihomosh "$HOME"/.local/bin/mihomosh
	if ! grep -qE '^eval\s"\$\(mihomosh' "$HOME"/.zshrc; then
		printf '%s\n' 'eval "$(mihomosh shell-completion zsh)"' >>"$HOME"/.zshrc
	fi
	echo "mihomosh can be used to control mihomo. mihomosh should be config first, use command: mihomosh config edit -e nvim"
}

if [[ ! -f ./mihomosh ]]; then
	echo "download mihomosh"
	mihomosh_tmp=$(mktemp -d)
	curl -fsSL -o "$mihomosh_tmp"/mihomosh.tar.gz "https://github.com/SamuNatsu/mihomosh/releases/download/v2.0.0/mihomosh-Linux-musl-x86_64.tar.gz"
	tar -zxf "$mihomosh_tmp"/mihomosh.tar.gz -C "$mihomosh_tmp"
	mv "$mihomosh_tmp"/mihomosh .
	rm -rf "$mihomosh_tmp"
	install_mihomosh
else
	install_mihomosh
fi

echo "config mihomo"

config_mihomo() {

	[[ -d /etc/mihomo ]] || sudo mkdir -p /etc/mihomo

	if [[ -d ./data ]]; then
		sudo cp -r ./data/* /etc/mihomo
	fi

	if [[ ! -L /etc/mihomo/config.yaml ]]; then
		sudo ln -sf "$(pwd)"/config.yaml /etc/mihomo/config.yaml
	fi

	if [[ ! -L /etc/systemd/system/mihomo.service ]]; then
		sudo ln -sf "$(pwd)"/mihomo.service /etc/systemd/system/mihomo.service
	fi

	sudo systemctl daemon-reload
	sudo systemctl enable mihomo.service
}

config_mihomo

echo "start mihomo"

sudo systemctl start mihomo.service

cd "$cdir"

echo "install mihomo done"
