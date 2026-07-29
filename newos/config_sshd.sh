#!/usr/bin/env bash

set -e

read -r -p "Make sure you have configured your ssh public key,otherwise the connection may be lost, are you ready? y or n: " ready
if [[ $ready = "y" ]]; then
	config_file="/etc/ssh/sshd_config"
	read -r -p "Input your ssh public key: " pubkey
	if [[ -z $pubkey ]]; then
		echo "Public key is required, exiting."
		exit 1
	fi
	test -d "$HOME"/.ssh || mkdir -p "$HOME"/.ssh
	echo "$pubkey" >"$HOME"/.ssh/authorized_keys
	sudo sed -i \
		-e 's/^[[:space:]]*#\?[[:space:]]*PermitRootLogin.*/PermitRootLogin no/' \
		-e 's/^[[:space:]]*#\?[[:space:]]*PasswordAuthentication.*/PasswordAuthentication no/' \
		-e 's/^[[:space:]]*#\?[[:space:]]*AllowAgentForwarding.*/AllowAgentForwarding yes/' \
		-e 's/^[[:space:]]*#\?[[:space:]]*AllowTcpForwarding.*/AllowTcpForwarding yes/' \
		"$config_file"

	read -r -p "input your allow users: " allow_users
	if [[ -z $allow_users ]]; then
		allow_users=$USER # default to current user
	fi
	if grep -qE "^\s*#?\s*AllowUsers" "$config_file"; then
		sudo sed -i -e 's/^[[:space:]]*#\?[[:space:]]*AllowUsers.*/AllowUsers '"$allow_users"'/' "$config_file"
	else
		sudo sed -i '$a AllowUsers '"$allow_users" "$config_file"
	fi

	echo "config sshd complete!"
fi
