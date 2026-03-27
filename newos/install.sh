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

DOCUMENTS_DIR="$HOME"/documents
DOWNLOADS_DIR="$HOME"/downloads
DOTFILES="$DOCUMENTS_DIR"/dotfiles
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

# update syste
_update_system() {
	sudo apt update && sudo apt upgrade -y
}

_install() {
	sudo apt install "$@" -y
}

# prepare
prepare() {
	info "check system"
	local support_os=("debian" "ubuntu")
	if [[ ! ${support_os[*]} =~ $OS ]]; then
		error "OS $OS is not supported"
		exit 1
	fi

	info "update system"
	_update_system

	info "install tools"
	_install make gcc ripgrep fd-find bat unzip git xclip curl wget jq

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
TMUX_VERSION="3.6"
GO_VERSION="1.26.1"

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
alias bat="batcat --theme base16"
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
		_install iptables iptables-persistent netfilter-persistent fail2ban
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
	if [[ ! -d $DOTFILES ]]; then
		mkdir -p "$DOTFILES"
		git clone https://gitee.com/inobit/dotfiles.git "$DOTFILES"
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

	info "config delta"
	if ! which git >/dev/null 2>&1; then
		warn "git not found, skip config delta."
	else
		local command_prefix="git config --global"
		declare -A configs
		configs["core.pager"]="delta"
		configs["interactive.diffFilter"]="delta --color-only"
		configs["delta.navigate"]=true
		configs["merge.conflictStyle"]="zdiff3"
		for key in "${!configs[@]}"; do
			$command_prefix "$key" "${configs[$key]}"
		done
		info "delta config done"
	fi
}

install_btop() {
	info "install btop"
	if ! which btop >/dev/null 2>&1; then
		_install btop
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
		if [[ -f "$DOTFILES"/newos/fzf/fzf_preview_handler.sh ]]; then
			info "config fzf preview handler"
			ln -sf "$DOTFILES"/newos/fzf/fzf_preview_handler.sh "$fzf_home"/fzf_preview_handler.sh
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
		local config_dir="$DOTFILES"/nvim
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
		cat <<'EOF' >"$HOME"/.local/bin/mycurl
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
		_install libevent-dev ncurses-dev build-essential bison pkg-config
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
		local tmux_config_file="$DOTFILES"/tmux/tmux.conf
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
		cp "$DOTFILES"/ssh/rc "$HOME"/.ssh
		info "ssh auth socks config done"
	else
		warn "ssh rc file not found, skip config."
	fi
}

install_node_env() {
	info "install fnm"
	FNM_PATH="$HOME/.local/share/fnm"
	if [[ ! -d $FNM_PATH ]]; then
		curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
	fi
	info "fnm installed"

	info "install node 22"
	if [[ -z $(find "$FNM_PATH"/node-versions -maxdepth 1 -type d -regex ".*v22[\.0-9]+$" 2>/dev/null) ]]; then
		"$FNM_PATH"/fnm install 22
	fi
	info "node 22 installed"

	"$FNM_PATH"/fnm default 22

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

install_go_env() {
	info "install go"
	if ! which go >/dev/null 2>&1; then
		GO_VERSION=${GO_VERSION:-"1.26.1"}
		local file_name="go${GO_VERSION}.linux-amd64.tar.gz"
		local full_name="$DOWNLOADS_DIR/$file_name"
		if [[ ! -f $full_name ]]; then
			info "downloading $file_name"
			curl -fSsL -o "$full_name" "https://go.dev/dl/$file_name"
		fi
		# Remove any previous Go installation (official instruction)
		test -d /usr/local/go && sudo rm -rf /usr/local/go
		# Extract into /usr/local, creating a Go tree in /usr/local/go
		sudo tar -C /usr/local -xzf "$full_name"
		info "go installed"
	else
		info "$(go version) is already installed"
	fi
}

install_docker() {
	read -r -p "Whether to install docker? y or n: " docker
	if [[ $docker = "y" ]]; then
		read -r -p "Rootless Docker? y or n: " rootless
		if [[ $rootless = "y" ]]; then
			info "install rootless docker"
			_install uidmap slirp4netns
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
			_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
			_user=$USER
			info "add $_user to docker group"
			sudo usermod -aG docker "$_user"
			info "please logout and login again to make the group take effect"
			info "root docker will auto expose mapped port, you can user DOCKER-USER chain control it: "
			info "first: reject all from specify eth interface"
			info ">> iptables -I DOCKER-USER -i eth0 -j DROP"
			info "then: add allowed port"
			info ">> iptables -I DOCKER-USER -i eth0 -p tcp --dport 80 -j ACCEPT"
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

install_gh() {
	info "install gh (GitHub CLI)"
	if ! which gh >/dev/null 2>&1; then
		(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
			&& sudo mkdir -p -m 755 /etc/apt/keyrings \
			&& out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
			&& cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null \
			&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
			&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
			&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
			&& sudo apt update \
			&& sudo apt install gh -y
		info "gh installed"
	else
		info "$(gh --version | head -1) is already installed"
	fi
}

install_zsh() {
	info "install zsh"
	if ! which zsh >/dev/null 2>&1; then
		_install zsh
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
	if [[ -f "$DOTFILES"/zsh/.zshrc ]]; then
		info "copy .zshrc"
		cp "$DOTFILES"/zsh/.zshrc "$HOME"/.zshrc
		info "config zsh done"
	else
		warn "zsh config file not found, skip config."
	fi
}

cp_shell_funcs() {
	info "copy shell functions to $HOME/.funcs"
	if [[ -d $DOTFILES/zsh/funcs ]]; then
		test -d "$HOME"/.funcs || mkdir -p "$HOME"/.funcs
		cp -r "$DOTFILES"/zsh/funcs/* "$HOME"/.funcs
	fi
	info "shell functions copied"
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

# 函数注册（格式：函数名|描述）
FUNC_REGISTRY=(
	"config_locale|配置系统语言环境"
	"config_timezone|配置系统时区"
	"config_env_and_alias|配置环境变量和别名"
	"config_proxy|配置系统代理"
	"config_ssh_agent|配置 SSH 代理"
	"config_firewall|配置防火墙规则"
	"pull_dotfiles|克隆 dotfiles 仓库"
	"install_git_delta|安装 git-delta"
	"install_btop|安装 btop 资源监视器"
	"install_fzf|安装 fzf 模糊搜索"
	"install_nvim|安装 Neovim 编辑器"
	"install_tmux|安装 tmux 终端复用器"
	"install_node_env|安装 Node.js 环境"
	"install_python_env|安装 Python 环境"
	"install_rust_env|安装 Rust 环境"
	"install_go_env|安装 Go 环境"
	"install_docker|安装 Docker 容器"
	"install_gh|安装 GitHub CLI"
	"install_zsh|安装 zsh 和插件"
	"cp_shell_funcs|复制 shell 函数"
	"ch_zsh|切换默认 shell 为 zsh"
)

main() {
	info "---------- install start ----------"
	detect_os
	local current_dir
	current_dir="$(pwd)"
	info "entry home dir"
	cd "$HOME"

	# 从注册表解析函数名和描述
	local functions=()
	declare -A FUNC_DESC
	for entry in "${FUNC_REGISTRY[@]}"; do
		local func="${entry%%|*}"
		local desc="${entry#*|}"
		functions+=("$func")
		FUNC_DESC["$func"]="$desc"
	done

	# 显示函数列表
	show_menu() {
		echo ""
		echo "可用函数列表:"
		echo "序号  函数名                描述"
		echo "----  --------------------  ----------------------------------------"
		for i in "${!functions[@]}"; do
			local func="${functions[$i]}"
			local desc="${FUNC_DESC[$func]}"
			printf "%2d    %-20s  %s\n" "$((i + 1))" "$func" "$desc"
		done
		echo ""
		echo "用法:"
		echo "  - 输入序号执行对应函数（多个序号用空格分隔，如: 1 3 5）"
		echo "  - 输入 'all' 执行所有函数"
		echo "  - 输入 'q' 或 'quit' 退出"
		echo ""
	}

	# 解析序号为函数名
	parse_numbers() {
		local input="$1"
		local -a result=()
		for num in $input; do
			if [[ "$num" =~ ^[0-9]+$ ]]; then
				local idx=$((num - 1))
				if [[ $idx -ge 0 && $idx -lt ${#functions[@]} ]]; then
					result+=("${functions[$idx]}")
				else
					warn "序号 $num 超出范围，忽略"
				fi
			else
				warn "无效序号 '$num'，忽略"
			fi
		done
		echo "${result[@]}"
	}

	local selected_functions=()
	local run_prepare=false
	local other_params=()

	# 先解析所有参数
	for param in "$@"; do
		if [[ "$param" == "-p" ]]; then
			run_prepare=true
		else
			other_params+=("$param")
		fi
	done

	if [ ${#other_params[@]} -eq 0 ]; then
		# 无其他参数时显示交互菜单
		show_menu
		read -r -p "请输入序号: " user_input

		if [[ "$user_input" == "q" || "$user_input" == "quit" ]]; then
			info "退出安装"
			cd "$current_dir"
			return
		elif [[ "$user_input" == "all" ]]; then
			selected_functions=("${functions[@]}")
		else
			selected_functions=($(parse_numbers "$user_input"))
		fi
	else
		# 有其他参数时检查是否为数字或函数名
		for param in "${other_params[@]}"; do
			if [[ "$param" =~ ^[0-9]+$ ]]; then
				# 参数是序号
				local idx=$((param - 1))
				if [[ $idx -ge 0 && $idx -lt ${#functions[@]} ]]; then
					selected_functions+=("${functions[$idx]}")
				else
					warn "序号 $param 超出范围，忽略"
				fi
			elif [[ " ${functions[*]} " == *" $param "* ]]; then
				# 参数是函数名
				selected_functions+=("$param")
			else
				warn "未知参数 '$param'，忽略"
			fi
		done
	fi

	# 执行 prepare
	if [[ "$run_prepare" == true ]]; then
		prepare
	fi

	if [[ ${#selected_functions[@]} -eq 0 ]]; then
		warn "未选择任何函数"
	else
		info "将执行以下函数: ${selected_functions[*]}"
	fi

	for func in "${selected_functions[@]}"; do
		$func
	done

	cd "$current_dir"
	info "---------- install end ----------"
}

main "$@"
