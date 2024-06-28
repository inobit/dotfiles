#!/usr/bin/env bash

set -e

# config proxy
read -r -p "input proxy address: " proxy
if [ -n "$proxy" ]; then
	export all_proxy=$proxy
	export no_proxy="127.0.0.1,localhost,::1"
	if grep -q 'ID=debian' /etc/os-release || grep -q 'ID=ubuntu' /etc/os-release; then
		test -f /etc/apt/apt.conf || sudo touch /etc/apt/apt.conf
		echo "Acquire::http::Proxy $proxy" >>/etc/apt/apt.conf
	fi
fi

echo "config ssh"
if [ -d "$HOME"/.ssh ]; then
	eval "$(ssh-agent)"
	for possiblekey in "${HOME}"/.ssh/*; do
		if grep -q PRIVATE "$possiblekey"; then
			ssh-add "$possiblekey"
		fi
	done
fi

echo "update system"
sudo apt update && sudo apt upgrade -y

echo "install tools"
sudo apt install make gcc ripgrep unzip git xclip curl wget -y

echo "pull dotfiles"
if [ ! -d "$HOME"/documents/dotfiles ]; then
	mkdir -p "$HOME"/documents/dotfiles
	git clone git@gitee.com:andrew_rogers/dotfiles.git "$HOME"/documents/dotfiles
fi

echo "install nvim"
if ! which nvim >/dev/null 2>&1; then
	sudo rm -rf /opt/nvim-linux64
	curl -LO https://github.com/neovim/neovim/releases/download/v0.10.0/nvim-linux64.tar.gz
	sudo tar -xzf nvim-linux64.tar.gz -C /opt
	sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/bin/nvim
fi

echo "ln nvim config"
test -d "$HOME"/.config || mkdir -p ~/.config
ln -sf "$HOME"/documents/dotfiles/nvim ~/.config/nvim

echo "install tmux"
if ! which tmux >/dev/null 2>&1; then
	sudo apt install libevent-dev ncurses-dev build-essential bison pkg-config -y
	# sudo apt install tmux
	if [ ! -f ./tmux-3.4.tar.gz ]; then
		curl -LO https://github.com/tmux/tmux/releases/download/3.4/tmux-3.4.tar.gz
	fi
	test -d ./tmux-3.4 && rm -rf ./tmux-3.4
	tar -zxf tmux-3.4.tar.gz
	cd ./tmux-3.4
	./configure && make
	sudo make install
fi

echo "config tmux"
test -d "$HOME"/.config/tmux || mkdir -p ~/.config/tmux
ln -sf "$HOME"/documents/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
if [ ! -d "$HOME"/.tmux/plugins/tpm ]; then
	git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm
fi
#tmux source "$HOME"/.config/tmux/tmux.conf

echo "install nvm"
if [ ! -d "$HOME"/.nvm ]; then
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

echo "install node 20 18"
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 20
nvm install 18

echo "install pyenv"
sudo apt install build-essential libssl-dev zlib1g-dev \
	libbz2-dev libreadline-dev libsqlite3-dev curl git \
	libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y

if [ ! -f ./.pyenv/bin/pyenv ]; then
	curl https://pyenv.run | bash
fi

python="3.12.3"
echo "install python $python"
if [ ! -f ./.pyenv/versions/$python/bin/python ]; then
	./.pyenv/bin/pyenv install "$python"
fi

echo "create nvim venv"
if [ ! -d "$HOME"/.nvim-venv ]; then
	./.pyenv/versions/$python/bin/python -m venv "$HOME"/.nvim-venv
	chmod a+x "$HOME"/.nvim-venv/bin/activate
fi

echo "install vscode-js-debug"
if [ ! -d "$HOME"/.dap-js/out ]; then
	rm -rf "$HOME"/.dap-js
	git clone https://github.com/microsoft/vscode-js-debug "$HOME"/.dap-js
	cd "$HOME"/.dap-js
	nvm use
	npm install --legacy-peer-deps
	npx gulp vsDebugServerBundle
	mv dist out
	cd "$HOME"
fi

echo "nvim config python and vscode-js-debug"
local_options="$HOME/documents/dotfiles/nvim/lua/config/local-options.lua"
rm -f "$local_options"
touch "$local_options"
echo 'vim.g.python3_host_prog = os.getenv "HOME" .. "/.nvim-venv/bin/python3"' >>"$local_options"
echo 'vim.g.vscode_js_debug_path = os.getenv "HOME" .. "/.dap-js"' >>"$local_options"

echo "install zsh"
sudo apt install zsh -y

echo "install oh-my-zsh"
rm -rf "$HOME"/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
echo "install zsh-autosuggestions"
git clone --depth 1 git@github.com:zsh-users/zsh-autosuggestions.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-autosuggestions
echo "install zsh-syntax-highlighting"
git clone --depth 1 git@github.com:zsh-users/zsh-syntax-highlighting.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
echo "install zsh-autocomplete"
git clone --depth 1 git@github.com:zsh-users/zsh-completions.git "$HOME"/.oh-my-zsh/custom/plugins/zsh-completions

echo "ln .zshrc"
ln -sf "$HOME"/documents/dotfiles/zsh/.zshrc "$HOME"/.zshrc

echo "change to zsh"
chsh -s /usr/bin/zsh
/usr/bin/zsh

echo "source .zshrc"
# shellcheck disable=SC1091
source "$HOME/.zshrc"
