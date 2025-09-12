#!/usr/bin/env bash

set -e

read -r -p "Make sure you have configured your ssh public key,otherwise the connection may be lost, are you ready? y or n: " ready
if [[ $ready = "y" ]]; then
	config_file="/etc/ssh/sshd_config"
	read -r -p "Use the default public key? y or n: " default
	if [[ $default = "y" ]]; then
		test -d "$HOME"/.ssh || mkdir -p "$HOME"/.ssh
		cat <<EOF >"$HOME"/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKjwdX9dgHod0boxQ+cGURMTsTdEHDwFDI4KB1ky/JfKB6wIIQFBLIEhNBp+t07LJ/Cz2VAiGlAA9FO92LGb2DItsS9Le3N/352Ig2M7GhoRMSe8UzTh/4mqNqVupph6vjK8Fyd3alK2JG6AeOj5pjRfCpTSGzPXMvs3YM4T9JyMvvKghOzeY/bxwskbGKEDfo7Z7OSrzbwcabT2u5FILfGMk9KR0CHyLgHRX98RYZeU2WesopEE3Lgw8IAH1gpQ+wDOsMhCbAeunc3RaSxzcvNLx4K2e/zg8RylmuxSZyRHNZs6UJtYJdundip1xGg4wo1QR6ilQjHbvEEZh2w1I76Sx07td2+rXSnLfRhMVQ9bav/CqNEbEcyjBJxfNh+TzJWwyG05tMhjFsR9imGbrrTYDk8syVHBbTppgBeXWtcB27TpdhZy4MGZ4FG0/YB0dJsMRCziOM0aAc1jahNvhQbjfomToQ5ZQPsqczlT2cb2MxWs3M/r6k51HRod68HOE= company
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4aP9fguXUOByA7Sc4Ccx8Tcpqtx1D5vd38lNHE3xaUUh0qiqrnsfOlngKaNVWbsbSyHTl8jrI4XlOUEJv3x1aqhJ3OqlN0Ictb9DmSW+PEeRwFV8b2yBmMNqhB+EFmSy598Vy0TliwZNJfNpWCvZ0jyKmscuKCwj2BRJFK1dbu0aVJ4x8Zbs0PzvvdHC8H3YnxBWIoApYSbTK/oQqlA/CDA50tkcueKZivZc09qfW/qBiOdkfr9Y9iy3nWp1JSdHOWvU5alxSMjFqA2DPndfeHa07xl0J/LrDWI/H3WATnmJLlXSPpg36HPFGPspcahFYejDu9+h5CQxalp7WLnT+Z1Bkw5ke14Ov7miMgQEZ6Qcm5IkjNZAuITEUW7PA4Ia1jbyN8FNh9HawpcgHf35hSGCeybYCo8ZOEBZgwQSdJluwij0oJ5WKtcbRTPG9H8ntQfjg4eIh1lUZ1YqzICmZP1VNB6KHAVFR+VflP5UgbThH56tfGnDaPEej0VW7w7k= home
EOF
	fi
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
		sed -i -e 's/^[[:space:]]*#\?[[:space:]]*AllowUsers.*/AllowUsers '"$allow_users"'/' "$config_file"
	else
		sudo sed -i '$a AllowUsers '"$allow_users" "$config_file"
	fi

	echo "config sshd complete!"
fi
