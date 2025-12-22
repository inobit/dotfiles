#!/bin/bash

set -e

# make sure you have set GPG_TTY
# Compress and encrypt
# tar -zcf - .mihomo | gpg -c -o mihomo.tar.gz.gpg
# Decrypt and decompress
# gpg -d mihomo.tar.gz.gpg | tar -zxf -

MIHOMO_HOME="$HOME"/.mihomo
CONFIG_DIR="$HOME/documents/dotfiles/mihomo"

prepare() {
	# set proxy
	read -r -p "input proxy address: " proxy
	if [[ -z $proxy ]]; then
		local client
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
		warn "proxy not set, some error may occur"
	fi

	# config timezone
	if [[ $(date +%z) != +0800 ]]; then
		which timedatectl 1>/dev/null 2>&1 && sudo timedatectl set-timezone Asia/Shanghai
	fi

	# create mihomo home
	test -d "$MIHOMO_HOME" || mkdir -p "$MIHOMO_HOME"
}

handle_config_file() {
	local file_names=("config.yaml" "mihomo.service")
	for file_name in "${file_names[@]}"; do
		if [[ ! -f $MIHOMO_HOME/$file_name ]]; then
			if [[ -f $CONFIG_DIR/$file_name ]]; then
				cp "$CONFIG_DIR/$file_name" "$MIHOMO_HOME"
			elif [[ -f ./$file_name ]]; then
				cp "./$file_name" "$MIHOMO_HOME"
			else
				echo "config file $file_name not found"
				exit 1
			fi
		fi
	done
}

install_mihomo() {
	local exec_file="$MIHOMO_HOME/mihomo"
	if [[ ! -f $exec_file ]]; then
		echo "download mihomo"
		curl -fSsL -o "$exec_file.gz" "https://github.com/MetaCubeX/mihomo/releases/download/v1.19.15/mihomo-linux-amd64-v2-v1.19.15.gz"
		gzip -d "$exec_file.gz"
	fi
	chmod +x "$exec_file"
	sudo ln -sf "$exec_file" /usr/local/bin/mihomo
}

install_mihomosh() {
	local exec_file="$MIHOMO_HOME/mihomosh"
	if [[ ! -f $exec_file ]]; then
		echo "download mihomosh"
		mihomosh_tmp=$(mktemp -d)
		curl -fsSL -o "$mihomosh_tmp"/mihomosh.tar.gz "https://github.com/SamuNatsu/mihomosh/releases/download/v2.0.0/mihomosh-Linux-musl-x86_64.tar.gz"
		tar -zxf "$mihomosh_tmp"/mihomosh.tar.gz -C "$mihomosh_tmp"
		mv "$mihomosh_tmp"/mihomosh "$MIHOMO_HOME"
		rm -rf "$mihomosh_tmp"
	fi
	chmod +x "$exec_file"
	test -d "$HOME"/.local/bin || mkdir -p "$HOME"/.local/bin
	ln -sf "$exec_file" "$HOME"/.local/bin/mihomosh
	if ! grep -qE '^eval\s"\$\(mihomosh' "$HOME"/.zshrc; then
		echo "eval $(mihomosh shell-completion zsh)" >>"$HOME"/.zshrc
	fi
	echo "mihomosh can be used to control mihomo. mihomosh should be config first, use command: mihomosh config edit -e nvim"
}

config_mihomo() {
	echo "config mihomo"

	[[ -d /etc/mihomo ]] || sudo mkdir -p /etc/mihomo

	if [[ -d $MIHOMO_HOME/data ]]; then
		sudo cp -r "$MIHOMO_HOME"/data/* /etc/mihomo
	fi

	if [[ ! -L /etc/mihomo/config.yaml ]]; then
		sudo ln -sf "$MIHOMO_HOME"/config.yaml /etc/mihomo/config.yaml
	fi

	if [[ ! -L /etc/systemd/system/mihomo.service ]]; then
		sudo ln -sf "$MIHOMO_HOME"/mihomo.service /etc/systemd/system/mihomo.service
	fi

	sudo systemctl daemon-reload
	sudo systemctl enable mihomo.service

	echo "set proxy-providers first, and then start mihomo!"
}

main() {
	echo "----- install mihomo start -----"
	prepare
	handle_config_file
	install_mihomo
	install_mihomosh
	config_mihomo
	echo "----- install mihomo done -----"
}

main "$@"
