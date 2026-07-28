#!/bin/bash

set -e

# make sure you have set GPG_TTY
# Compress and encrypt
# tar -zcf - .mihomo | gpg -c -o mihomo.tar.gz.gpg
# Decrypt and decompress
# gpg -d mihomo.tar.gz.gpg | tar -zxf -

MIHOMO_HOME="$HOME"/.mihomo
CONFIG_DIR="$HOME/documents/dotfiles/mihomo"
MIHOMO_VERSION="v1.19.29"

prepare() {
	# set proxy
	read -r -p "input proxy address: " proxy
	if [[ -z $proxy ]]; then
		local client
		client=$(echo "$SSH_CLIENT" | awk '{print $1}')
		if [[ -n $client ]]; then
			echo "Trying to use client's proxy"
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
		echo "proxy not set, some error may occur"
	fi

	# config timezone
	if [[ $(date +%z) != +0800 ]]; then
		command -v timedatectl >/dev/null 2>&1 && sudo timedatectl set-timezone Asia/Shanghai
	fi

	# create mihomo home
	[[ -d $MIHOMO_HOME ]] || mkdir -p "$MIHOMO_HOME"
}

handle_config_file() {
	local file_names=("config.yaml" "mihomo.service")
	for file_name in "${file_names[@]}"; do
		if [[ ! -f "$MIHOMO_HOME/$file_name" ]]; then
			if [[ -f "$CONFIG_DIR/$file_name" ]]; then
				cp "$CONFIG_DIR/$file_name" "$MIHOMO_HOME"
			elif [[ -f "./$file_name" ]]; then
				cp "./$file_name" "$MIHOMO_HOME"
			else
				echo "config file $file_name not found"
				exit 1
			fi
		fi
	done
}

install_mihomo() {
	if [[ -z $MIHOMO_VERSION ]]; then
		echo "MIHOMO_VERSION is not set, please set it first"
		exit 1
	fi
	local exec_file="$MIHOMO_HOME/mihomo"
	if [[ ! -f $exec_file ]]; then
		echo "download mihomo"
		curl -fSsL -o "$exec_file.gz" "https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/mihomo-linux-amd64-v2-${MIHOMO_VERSION}.gz"
		gzip -d "$exec_file.gz"
	fi
	chmod +x "$exec_file"
	sudo ln -sf "$exec_file" /usr/local/bin/mihomo
}

install_mihomoctl() {
	local exec_file="$MIHOMO_HOME/mihomoctl"
	if [[ ! -f $exec_file ]]; then
		echo "download mihomoctl"
		local download_url
		download_url=$(curl -fsSL "https://api.github.com/repos/inobit/mihomoctl/releases/latest" | grep -o '"browser_download_url": "[^"]*linux_amd64[^"]*"' | head -1 | cut -d'"' -f4)
		if [[ -z $download_url ]]; then
			echo "failed to get mihomoctl download url, check network or GitHub API rate limit"
			exit 1
		fi
		ctl_tmp=$(mktemp -d)
		curl -fsSL -o "$ctl_tmp"/mihomoctl.tar.gz "$download_url"
		tar -zxf "$ctl_tmp"/mihomoctl.tar.gz -C "$ctl_tmp"
		mv "$ctl_tmp"/mihomoctl "$MIHOMO_HOME"
		rm -rf "$ctl_tmp"
	fi
	chmod +x "$exec_file"
	sudo ln -sf "$exec_file" /usr/local/bin/mihomoctl
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
	install_mihomoctl
	config_mihomo
	echo "----- install mihomo done -----"
}

main "$@"
