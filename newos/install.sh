#!/usr/bin/env bash

set -e

cd "$HOME"

# config locale
echo "set locale"
locale_file="/etc/locale.gen"
sudo sed -i \
	-e '/^# en_DK.UTF-8/s/^# //g' \
	-e '/^# en_US.UTF-8/s/^# //g' \
	-e '/^# zh_CN.UTF-8/s/^# //g' \
	"$locale_file"
sudo locale-gen
sudo update-locale LANG=en_US.UTF-8 LC_TIME=en_DK.UTF-8

# config env and alias for login shell
echo "config env and alias"
if [[ ! -f $HOME/.profile ]] || ! grep -q "^# config env and alias for login shell$" "$HOME"/.profile; then
	cat <<EOF | tee -a "$HOME"/.profile >/dev/null

# config env and alias for login shell

export EDITOR='nvim'

# Use nvim as manpager
export MANPAGER='nvim +Man!'
export MANWIDTH=999

alias setproxy="export ALL_PROXY=http://127.0.0.1:7890"
alias unsetproxy="unset ALL_PROXY"
alias vim="nvim"
alias fd="fdfind"
alias bat="batcat"
alias cat="bat --paging=never"
export NO_PROXY="127.0.0.1,localhost,::1"
export TIME_STYLE="long-iso"
EOF
fi
if [[ ! -f $HOME/.zprofile ]] || ! grep -q "^# source .profile$" "$HOME"/.zprofile; then
	printf "# source .profile\n. \"\$HOME/.profile\"\n" | tee -a "$HOME"/.zprofile >/dev/null
fi

# config proxy
read -r -p "input proxy address: " proxy
if [[ -n $proxy ]]; then
	export ALL_PROXY=$proxy
	export NO_PROXY="127.0.0.1,localhost,::1"
	if grep -q 'ID=debian' /etc/os-release || grep -q 'ID=ubuntu' /etc/os-release; then
		test -f /etc/apt/apt.conf || sudo touch /etc/apt/apt.conf
		if grep -q '^Acquire' /etc/apt/apt.conf; then
			sudo sed -i '/^Acquire/d' /etc/apt/apt.conf
		fi
		echo "Acquire::http::Proxy \"$proxy\";" | sudo tee -a /etc/apt/apt.conf >/dev/null
	fi

fi

# config ssh agent
read -r -p "Whether to config ssh agent? y or n: " config_ssh_agent
if [[ $config_ssh_agent = "y" ]]; then
	if [[ -d $HOME/.ssh ]]; then
		eval "$(ssh-agent)"
		for possiblekey in "${HOME}"/.ssh/*; do
			if grep -q PRIVATE "$possiblekey"; then
				ssh-add "$possiblekey"
			fi
		done
	fi
fi

echo "update system"
sudo apt update && sudo apt upgrade -y

echo "install tools"
sudo apt install make gcc ripgrep fd-find bat unzip git xclip curl wget jq -y

if ! which fzf >/dev/null 2>&1; then
	echo "install fzf"
	fzf_home="$HOME"/.fzf
	fzf_version=0.65.2
	curl -fSsL --create-dirs -o "$fzf_home"/bin/fzf.tar.gz https://github.com/junegunn/fzf/releases/download/v"$fzf_version"/fzf-"$fzf_version"-linux_amd64.tar.gz
	tar -zxf "$fzf_home"/bin/fzf.tar.gz -C "$fzf_home"/bin
	rm -f "$fzf_home"/bin/fzf.tar.gz
	test -d "$HOME"/.local/bin || mkdir -p "$HOME"/.local/bin
	ln -sf "$fzf_home"/bin/fzf "$HOME"/.local/bin/fzf
	ln -sf "$HOME"/documents/dotfiles/newos/fzf/fzf_preview_handler.sh "$fzf_home"/fzf_preview_handler.sh
fi

# config firewall
read -r -p "Whether to config iptables? y or n: " config_iptables
if [[ $config_iptables = "y" ]]; then
	sudo apt install iptables netfilter-persistent fail2ban -y
	# add rules
	IPTABLES_CMD="sudo iptables -t filter"
	$IPTABLES_CMD -I INPUT -i lo -j ACCEPT                                # allow local lo
	$IPTABLES_CMD -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # allow established and related
	$IPTABLES_CMD -I INPUT -p icmp -j ACCEPT                              # allow ping
	$IPTABLES_CMD -I INPUT -p tcp --dport 22 -j ACCEPT                    # allow ssh
	$IPTABLES_CMD -A INPUT -j REJECT                                      # reject all other
	sudo netfilter-persistent save                                        # save rules

	# config fail2ban
	cat <<EOF | sudo tee "/etc/fail2ban/jail.local" >/dev/null
[DEFAULT]
backend = systemd
bantime = 1d
[sshd]
enabled = true
EOF
	sudo systemctl restart fail2ban
fi

echo "pull dotfiles"
if [[ ! -d $HOME/documents/dotfiles ]]; then
	mkdir -p "$HOME"/documents/dotfiles
	git clone git@gitee.com:inobit/dotfiles.git "$HOME"/documents/dotfiles
fi

echo "install nvim"
if ! which nvim >/dev/null 2>&1; then
	sudo rm -rf /opt/nvim-linux64
	curl -fSsL -o nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-x86_64.tar.gz
	sudo tar -xzf nvim-linux-x86_64.tar.gz -C /opt
	sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/bin/nvim
fi

echo "ln nvim config"
test -d "$HOME"/.config || mkdir -p "$HOME"/.config
ln -sf "$HOME"/documents/dotfiles/nvim "$HOME"/.config/nvim

echo "install tree-sitter"
if [[ ! -f $HOME/.local/bin/tree-sitter ]]; then
	test -d "$HOME"/.local/bin || mkdir -p "$HOME"/.local/bin
	curl -fSsLO https://github.com/tree-sitter/tree-sitter/releases/download/v0.25.9/tree-sitter-linux-x64.gz
	gunzip tree-sitter-linux-x64.gz
	chmod a+x tree-sitter-linux-x64
	mv tree-sitter-linux-x64 "$HOME"/.local/bin/tree-sitter
fi

echo "install tmux"
if ! which tmux >/dev/null 2>&1; then
	sudo apt install libevent-dev ncurses-dev build-essential bison pkg-config -y
	# sudo apt install tmux
	if [[ ! -f ./tmux-3.4.tar.gz ]]; then
		curl -fSsLO https://github.com/tmux/tmux/releases/download/3.4/tmux-3.4.tar.gz
	fi
	test -d ./tmux-3.4 && rm -rf ./tmux-3.4
	tar -zxf tmux-3.4.tar.gz
	cd ./tmux-3.4
	./configure && make
	sudo make install
	cd "$HOME"
fi

echo "config tmux"
test -d "$HOME"/.config/tmux || mkdir -p "$HOME"/.config/tmux
ln -sf "$HOME"/documents/dotfiles/tmux/tmux.conf "$HOME"/.config/tmux/tmux.conf
if [[ ! -d $HOME/.tmux/plugins/tpm ]]; then
	git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm
fi
#tmux source "$HOME"/.config/tmux/tmux.conf

echo "install nvm"
if [[ ! -d $HOME/.nvm ]]; then
	# get latest release version
	version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name')
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/"$version"/install.sh | bash
fi

echo "install node 20 18"
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 18
nvm install 20
nvm alias default 20

echo "install pnpm"
if [[ ! -d $HOME/.local/share/pnpm ]]; then
	curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

echo "install uv"
if [[ ! -f $HOME/.local/bin/uv ]]; then
	curl -LsSf https://astral.sh/uv/install.sh | sh
fi

read -r -p "Whether to install docker(os must be debian)? y or n: " docker
if [[ $docker = "y" ]]; then
	# uninstall all conflicting packages
	for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

	# Add Docker's official GPG key:
	sudo apt-get update
	sudo apt-get install ca-certificates curl -y
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources:
	# shellcheck disable=SC1091
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
		sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	sudo apt-get update
	# install the latest version
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi

echo "config docker-daemon proxy"
docker_proxy="$proxy"
test -n "$docker_proxy" || docker_proxy="http://localhost:7890"
test -f /etc/docker/daemon.json || sudo touch /etc/docker/daemon.json
cat <<EOF | sudo tee "/etc/docker/daemon.json" >/dev/null
{
  "proxies": {
    "http-proxy": "$docker_proxy",
    "https-proxy": "$docker_proxy",
    "no-proxy": "localhost,127.0.0.1,docker-registry.example.com,.corp"
  }
}
EOF

echo "install zsh"
sudo apt install zsh -y

echo "install oh-my-zsh"
if [[ ! -d $HOME/.oh-my-zsh ]]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
fi
if [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
	echo "install zsh-autosuggestions"
	git clone --depth 1 git@github.com:zsh-users/zsh-autosuggestions.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]; then
	echo "install zsh-syntax-highlighting"
	git clone --depth 1 git@github.com:zsh-users/zsh-syntax-highlighting.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi
if [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete ]]; then
	echo "install zsh-autocomplete"
	git clone --depth 1 git@github.com:marlonrichert/zsh-autocomplete.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-autocomplete
fi
if [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-completions ]]; then
	echo "install zsh-autocomplete"
	git clone --depth 1 git@github.com:zsh-users/zsh-completions.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-completions
fi
echo "copy .zshrc"
cp "$HOME"/documents/dotfiles/zsh/.zshrc "$HOME"/.zshrc

echo "change to zsh"
chsh -s /usr/bin/zsh

echo "installation complete!"
echo "switching to zsh shell now..."
exec zsh
