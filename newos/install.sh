#!/usr/bin/env bash

set -e

# ANSI color codes
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
NC='\033[0m' # No Color
# Info function: Green color
info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}
# Warn function: Yellow color
warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}
# Error function: Red color
error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

DOWNLOADS_DIR="$HOME"/downloads
LOCAL_BIN_DIR="$HOME"/.local/bin
LOCAL_CONFIG_DIR="$HOME"/.config

# detect os
OS="UNKONWN"
detect_os() {
	if [[ -f /etc/os-release ]]; then
		. /etc/os-release
		OS=$ID
	fi
}

# prepare
prepare() {
	info "check system"
	detect_os
	local support_os=("debian" "ubuntu")
	if [[ ! ${support_os[*]} =~ $OS ]]; then
		error "OS $OS is not supported"
		exit 1
	fi

	info "update system"
	sudo apt update && sudo apt upgrade -y

	info "install tools"
	sudo apt install make gcc ripgrep fd-find bat unzip git xclip curl wget jq -y

	info "mkdir downloads"
	test -d "$DOWNLOADS_DIR" || mkdir -p "$DOWNLOADS_DIR"

	info "mkdir local bin"
	test -d "$LOCAL_BIN_DIR" || mkdir -p "$LOCAL_BIN_DIR"

	info "mkdir local config"
	test -d "$LOCAL_CONFIG_DIR" || mkdir -p "$LOCAL_CONFIG_DIR"

	info "prepare done."
}

# functions

# versions
GIT_DELTA_VERSION="0.18.2"
FZF_VERSION="0.65.2"
NVIM_VERSION="0.11.4"
TREE_SITTER_VERSION="0.25.9"
TMUX_VERSION="3.4"

# config locale
config_locale() {
	info "set locale"
	local locale_file="/etc/locale.gen"
	local locale_patterns=("en_US.UTF-8" "zh_CN.UTF-8" "en_DK.UTF-8")
	local effected=0
	for locale_pattern in "${locale_patterns[@]}"; do
		if grep -qE "^#\s*$locale_pattern" "$locale_file"; then
			sudo sed -i "/^#\s*$locale_pattern/s/^#\s*//g" "$locale_file"
			effected=$((effected + 1))
		fi
	done
	if [[ $effected -gt 0 ]]; then
		sudo locale-gen
		sudo update-locale LANG=en_US.UTF-8 LC_TIME=en_DK.UTF-8
	fi
	info "locale configed"
}

# config timezone
config_timezone() {
	info "config timezone"
	if [[ $(date +%z) != +0800 ]]; then
		if which timedatectl 1>/dev/null 2>&1; then
			sudo timedatectl set-timezone Asia/Shanghai
			info "timezone configed"
		else
			warn "timedatectl not found, please install it first, skip config."
		fi
	else
		info "timezone is already right"
	fi
}

# config env and alias for login shell
config_env_and_alias() {
	info "config env and alias"
	if [[ ! -f $HOME/.profile ]] || ! grep -q "^# config env and alias for login shell$" "$HOME"/.profile; then
		cat <<EOF | tee -a "$HOME"/.profile >/dev/null

# config env and alias for login shell

export EDITOR='nvim'

# Use nvim as manpager
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# history control
export HISTCONTROL=ignoreboth

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
	info "env and alias configed"
}

# config proxy
config_proxy() {
	info "config proxy"
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
		info "Proxy config done."
	else
		warn "Proxy config canceled."
	fi
}

# config ssh agent
config_ssh_agent() {
	info "config ssh agent"
	read -r -p "Whether to config ssh agent? y or n: " config_ssh_agent
	if [[ $config_ssh_agent = "y" ]]; then
		if [[ -d $HOME/.ssh ]]; then
			eval "$(ssh-agent)"
			for possiblekey in "${HOME}"/.ssh/*; do
				if grep -q PRIVATE "$possiblekey"; then
					ssh-add "$possiblekey"
				fi
			done
			info "ssh agent config done."
		fi
	else
		warn "ssh agent config canceled."
	fi
}

# config firewall
config_firewall() {
	read -r -p "Whether to config iptables? y or n: " config_iptables
	if [[ $config_iptables = "y" ]]; then
		sudo apt install iptables netfilter-persistent fail2ban -y
		# add rules
		if ! sudo iptables -t filter -nvL | grep -iE "dpt:22"; then
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
		else
			warn "iptables rules already configured, skip config."
		fi
	else
		warn "firewall config canceled."
	fi
}

# get dotfiles
pull_dotfiles() {
	info "pull dotfiles"
	if [[ ! -d $HOME/documents/dotfiles ]]; then
		mkdir -p "$HOME"/documents/dotfiles
		git clone https://gitee.com/inobit/dotfiles.git "$HOME"/documents/dotfiles
	fi
	info "pull dotfiles done"
}

# git-delta
install_git_delta() {
	info "install git-delta"
	if ! which delta >/dev/null 2>&1; then
		GIT_DELTA_VERSION=${GIT_DELTA_VERSION:-"0.18.2"}
		file_name="git-delta_${GIT_DELTA_VERSION}_amd64.deb"
		full_name="$DOWNLOADS_DIR/$file_name"
		if [[ ! -f "$DOWNLOADS_DIR/$file_name" ]]; then
			info "downloading $file_name"
			curl -fsSLo "$full_name" "https://github.com/dandavison/delta/releases/download/$GIT_DELTA_VERSION/$file_name"
		fi
		sudo dpkg -i "$full_name"
		info "git-delta installed"
	else
		info "$(delta --version) is already installed"
	fi
}

install_btop() {
	info "install btop"
	if ! which btop >/dev/null 2>&1; then
		sudo apt install btop -y
		info "btop installed"
	else
		info "$(btop --version) is already installed"
	fi

	info "config btop"
	test -d "$HOME"/.config || mkdir -p "$HOME"/.config
	file="$HOME/.config/btop/btop.conf"
	if [[ ! -f $file ]]; then
		warn "btop config file not found, skip config."
	else
		if sed -Ei "s/^(vim_keys\s*=\s*)(False)/\1True/" "$file"; then
			info "btop vim_keys configed"
		fi
	fi
}

# install fzf
install_fzf() {
	info "install fzf"
	if [[ ! -f "$HOME"/.local/bin/fzf ]]; then
		FZF_VERSION=${FZF_VERSION:-"0.65.2"}
		local fzf_home="$HOME/.fzf"
		curl -fSsL --create-dirs -o "$fzf_home"/bin/fzf.tar.gz https://github.com/junegunn/fzf/releases/download/v"$FZF_VERSION"/fzf-"$FZF_VERSION"-linux_amd64.tar.gz
		tar -zxf "$fzf_home"/bin/fzf.tar.gz -C "$fzf_home"/bin
		rm -f "$fzf_home"/bin/fzf.tar.gz
		test -d "$HOME"/.local/bin || mkdir -p "$HOME"/.local/bin
		ln -sf "$fzf_home"/bin/fzf "$HOME"/.local/bin/fzf
		if [[ -f "$HOME"/documents/dotfiles/newos/fzf/fzf_preview_handler.sh ]]; then
			info "config fzf preview handler"
			ln -sf "$HOME"/documents/dotfiles/newos/fzf/fzf_preview_handler.sh "$fzf_home"/fzf_preview_handler.sh
		else
			warn "fzf_preview_handler.sh not found, skip config preview handler."
		fi
	fi
	info "fzf installed"
}

install_nvim() {
	info "install nvim"
	if ! which nvim >/dev/null 2>&1; then
		NVIM_VERSION=${NVIM_VERSION:-"0.11.4"}
		info "nvim version to install: $NVIM_VERSION"
		local base_name="nvim-linux-x86_64"
		local file_name="$base_name.tar.gz"
		local full_name="$DOWNLOADS_DIR/$file_name"
		if [[ ! -f $full_name ]]; then
			info "downloading $file_name"
			curl -fSsL -o "$full_name" "https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/$file_name"
		fi
		sudo tar -xzf "$full_name" -C /opt
		sudo ln -sf "/opt/$base_name/bin/nvim" /usr/bin/nvim
		info "nvim installed"
	else
		info "nvim $(nvim --version | awk 'NR==1 {print $2}') has already installed"
	fi

	info "config nvim"
	test -d "$HOME"/.config || mkdir -p "$HOME"/.config
	if [[ ! -L $HOME/.config/nvim ]]; then
		local config_dir="$HOME"/documents/dotfiles/nvim
		if [[ -d $config_dir ]]; then
			ln -sf "$config_dir" "$HOME"/.config/nvim
			info "nvim config done"
		else
			warn "nvim config file not found, skip config."
		fi
	else
		info "nvim config done"
	fi

	info "install tree-sitter"
	if [[ ! -f $HOME/.local/bin/tree-sitter ]]; then
		TREE_SITTER_VERSION=${TREE_SITTER_VERSION:-"0.25.9"}
		test -d "$HOME"/.local/bin || mkdir -p "$HOME"/.local/bin
		local file_name="tree-sitter-linux-x64.gz"
		local full_name="$DOWNLOADS_DIR/$file_name"
		local file_base_name
		file_base_name="${full_name%.*}"
		if [[ ! -f $full_name ]]; then
			info "downloading $file_name"
			curl -fSsLo "$full_name" https://github.com/tree-sitter/tree-sitter/releases/download/v"$TREE_SITTER_VERSION"/"$file_name"
		fi
		gunzip -k -c "$full_name" >"$file_base_name"
		chmod a+x "$file_base_name"
		mv "$file_base_name" "$HOME"/.local/bin/tree-sitter
	fi
	info "tree-sitter installed"

	info "custom mycurl"
	if [[ ! -x $HOME/.local/bin/mycurl ]]; then
		cat <<EOF >"$HOME"/.local/bin/mycurl
#!/bin/bash
/usr/bin/curl --no-buffer "$@"
EOF
		chmod a+x "$HOME"/.local/bin/mycurl
	fi
	info "mycurl config done"
}

install_tmux() {
	info "install tmux"
	if ! which tmux >/dev/null 2>&1; then
		TMUX_VERSION=${TMUX_VERSION:-"3.4"}
		sudo apt install libevent-dev ncurses-dev build-essential bison pkg-config -y
		# sudo apt install tmux
		local base_name="tmux-$TMUX_VERSION"
		local file_name="$base_name.tar.gz"
		local full_name="$DOWNLOADS_DIR/$file_name"
		local source_dir="$DOWNLOADS_DIR/$base_name"
		if [[ ! -f $full_name ]]; then
			info "downloading $file_name"
			curl -fSsLo "$full_name" "https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/$file_name"
		fi
		test -d "$source_dir" && rm -rf "$source_dir"
		tar -zxf "$full_name" -C "$DOWNLOADS_DIR"
		local pwd
		pwd="$(pwd)"
		cd "$source_dir"
		./configure && make
		sudo make install
		cd "$pwd"
		info "tmux installed"
	else
		info "$(tmux -V) is already installed"
	fi

	info "config tmux"
	test -d "$HOME"/.config/tmux || mkdir -p "$HOME"/.config/tmux
	if [[ ! -L $HOME/.config/tmux/tmux.conf ]]; then
		local tmux_config_file="$HOME"/documents/dotfiles/tmux/tmux.conf
		if [[ -f $tmux_config_file ]]; then
			ln -sf "$tmux_config_file" "$HOME"/.config/tmux/tmux.conf
			info "tmux config done"
		else
			warn "tmux config file not found, skip config."
		fi
	else
		info "tmux config done"
	fi

	info "install tmux plugin manager"
	if [[ ! -d $HOME/.tmux/plugins/tpm ]]; then
		git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm
	fi
	info "plugin manager installed"

	info "config ssh auth socks"
	if [[ -f $HOME/documents/dotfiles/ssh/rc ]]; then
		test -d "$HOME"/.ssh || mkdir -p "$HOME"/.ssh
		cp "$HOME"/documents/dotfiles/ssh/rc "$HOME"/.ssh
		info "ssh auth socks config done"
	else
		warn "ssh rc file not found, skip config."
	fi
}

install_node_env() {
	info "install nvm"
	if [[ ! -d $HOME/.nvm ]]; then
		# get latest release version
		version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name')
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/"$version"/install.sh | bash
	fi
	info "nvm installed"

	# shellcheck disable=SC1091
	source "$HOME/.nvm/nvm.sh"
	info "install node 22"
	if [[ -z $(find "$HOME"/.nvm/versions/node -maxdepth 1 -type d -regex ".*v22[\.0-9]+$" 2>/dev/null) ]]; then
		nvm install 22
	fi
	info "node 22 installed"

	info "install node 20"
	if [[ -z $(find "$HOME"/.nvm/versions/node -maxdepth 1 -type d -regex ".*v20[\.0-9]+$" 2>/dev/null) ]]; then
		nvm install 20
	fi
	info "node 20 installed"

	nvm alias default 22

	info "install pnpm"
	if [[ ! -d $HOME/.local/share/pnpm ]]; then
		curl -fsSL https://get.pnpm.io/install.sh | sh -
	fi
	info "pnpm installed"
}

install_python_env() {
	info "install uv"
	if [[ ! -f $HOME/.local/bin/uv ]]; then
		curl -LsSf https://astral.sh/uv/install.sh | sh
	fi
	info "uv installed"
}

install_rust_env() {
	info "install rustup"
	if [[ ! -d $HOME/.rustup ]]; then
		curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
	fi
	info "rustup installed"
}

install_docker() {
	read -r -p "Whether to install docker? y or n: " docker
	if [[ $docker = "y" ]]; then
		read -r -p "Rootless Docker? y or n: " rootless
		if [[ $rootless = "y" ]]; then
			info "install rootless docker"
			sudo apt install -y uidmap
			export DOCKER_BIN="$HOME/.docker-bin"
			curl -fsSL https://get.docker.com/rootless | sh
			sudo loginctl enable-linger "$USER" # enable user-level services to run after logout
			info "rootless docker installed"
		else
			info "install root mode docker"
			info "uninstall all conflicting packages"
			sudo apt remove "$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)"

			info "add Docker's official GPG key":
			sudo apt-get update
			sudo apt-get install ca-certificates curl -y
			sudo install -m 0755 -d /etc/apt/keyrings
			sudo curl -fsSL "https://download.docker.com/linux/$OS/gpg" -o /etc/apt/keyrings/docker.asc
			sudo chmod a+r /etc/apt/keyrings/docker.asc

			if [[ $OS == "ubuntu" ]]; then
				# Add the repository to Apt sources:
				sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
			elif [[ $OS == "debian" ]]; then
				sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
			fi
			sudo apt-get update
			info "install the latest version"
			sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
			info "root mode docker installed"
		fi

		read -r -p "Whether to config docker-daemon proxy? y or n: " docker_proxy
		if [[ $docker_proxy = "y" ]]; then
			info "config docker-daemon proxy"
			docker_proxy="$ALL_PROXY"
			test -n "$docker_proxy" || docker_proxy="http://localhost:7890"
			local docker_file
			if [[ $rootless = "y" ]]; then
				test -d "$HOME/.config/docker" || mkdir -p "$HOME/.config/docker"
				docker_file="$HOME/.config/docker/daemon.json"
				test -f "$docker_file" || touch "$docker_file"
			else
				test -d /etc/docker || sudo mkdir -p /etc/docker
				docker_file="/etc/docker/daemon.json"
				test -f "$docker_file" || sudo touch "$docker_file"
			fi
			temp_daemon_json=$(mktemp)
			cat <<EOF >"$temp_daemon_json"
{
  "proxies": {
    "http-proxy": "$docker_proxy",
    "https-proxy": "$docker_proxy",
    "no-proxy": "localhost,127.0.0.1,docker-registry.example.com,.corp"
  }
}
EOF
			if [[ "$rootless" == "y" ]]; then
				mv "$temp_daemon_json" "$docker_file"
				chmod 644 "$docker_file"
			else
				sudo mv "$temp_daemon_json" "$docker_file"
				sudo chmod 644 "$docker_file"
			fi
			info "docker proxy config done"
		fi
	else
		warn "docker install canceled."
	fi
}

install_zsh() {
	info "install zsh"
	if ! which zsh >/dev/null 2>&1; then
		sudo apt install zsh -y
		info "zsh installed"
	else
		info "$(zsh --version) has already installed"
	fi

	info "install oh-my-zsh"
	if [[ ! -d $HOME/.oh-my-zsh ]]; then
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	fi
	info "oh-my-zsh installed"

	info "install plugin zsh-autosuggestions"
	if [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
		git clone --depth 1 git@github.com:zsh-users/zsh-autosuggestions.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	fi
	info "zsh-autosuggestions installed"

	info "install plugin zsh-syntax-highlighting"
	if [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]; then
		git clone --depth 1 git@github.com:zsh-users/zsh-syntax-highlighting.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
	fi
	info "zsh-syntax-highlighting installed"

	info "install plugin zsh-autocomplete"
	if [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete ]]; then
		echo "install zsh-autocomplete"
		git clone --depth 1 git@github.com:marlonrichert/zsh-autocomplete.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-autocomplete
	fi
	info "zsh-autocomplete installed"

	info "install plugin zsh-completions"
	if [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-completions ]]; then
		git clone --depth 1 git@github.com:zsh-users/zsh-completions.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-completions
	fi
	info "zsh-completions installed"

	info "config zsh"
	if [[ -f "$HOME"/documents/dotfiles/zsh/.zshrc ]]; then
		info "copy .zshrc"
		cp "$HOME"/documents/dotfiles/zsh/.zshrc "$HOME"/.zshrc
		info "config zsh done"
	else
		warn "zsh config file not found, skip config."
	fi
}

ch_zsh() {
	if [[ -x /usr/bin/zsh ]]; then
		info "change login shell to zsh"
		chsh -s /usr/bin/zsh
		info "switching to zsh shell now..."
		warn "some settings need to be logged in again"
		exec zsh
	else
		warn "zsh not installed, skip ch_zsh."
	fi
}

main() {
	info "---------- install start ----------"
	local current_dir
	current_dir="$(pwd)"
	info "entry home dir"
	cd "$HOME"
	# register all functions
	functions=(
		config_locale
		config_timezone
		config_env_and_alias
		config_proxy
		config_ssh_agent
		config_firewall
		pull_dotfiles
		install_git_delta
    install_btop
		install_fzf
		install_nvim
		install_tmux
		install_node_env
		install_python_env
		install_rust_env
		install_docker
		install_zsh
		ch_zsh)

	declare -A valid_functions
	for func in "${functions[@]}"; do
		valid_functions[$func]=1
	done

	local selected_functions=()
	if [ $# -eq 0 ]; then
		selected_functions=("${functions[@]}")
	else
		for param in "$@"; do
			if [[ -n "${valid_functions[$param]}" ]]; then
				selected_functions+=("$param")
			else
				info "Warning: Unknown function '$param', skipping."
			fi
		done
	fi

	prepare
	for func in "${selected_functions[@]}"; do
		$func
	done
	cd "$current_dir"
	info "---------- install end ----------"
}

main "$@"
