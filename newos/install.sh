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

echo "update system"
sudo apt update && sudo apt upgrade -y

echo "install zsh"
sudo apt install zsh -y
chsh -s /usr/bin/zsh

echo "install tools"
sudo apt install make gcc ripgrep unzip git xclip curl wget -y

echo "pull dotfiles"
test -d "$HOME"/documents || mkdir -p ~/documents
git clone git@gitee.com:andrew_rogers/dotfiles.git "$HOME"/documents/dotfiles

echo "install oh-my-zsh"
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
echo "install zsh-autosuggestions"
git clone --depth 1 git://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM"/plugins/zsh-autosuggestions
echo "install zsh-syntax-highlighting"
git clone --depth 1 git://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM"/plugins/zsh-syntax-highlighting
echo "install zsh-autocomplete"
git clone --depth 1 git://github.com/zsh-users/zsh-autocomplete.git "$ZSH_CUSTOM"/plugins/zsh-autocomplete
ls -sf "$HOME"/documents/dotfiles/zsh/.zshrc ~/.zshrc

echo "install nvim"
curl -LO https://github.com/neovim/neovim/releases/download/v0.10.0/nvim-linux64.tar.gz
sudo tar -xzf nvim-linux64.tar.gz -C /opt
sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/bin/nvim

echo "ln nvim config"
test -d "$HOME"/.config || mkdir -p ~/.config
ln -sf "$HOME"/documents/dotfiles/nvim ~/.config/nvim

echo "install tmux"
# sudo apt install tmux
curl -LO https://github.com/tmux/tmux/releases/download/3.4/tmux-3.4.tar.gz
tar -zxv tmux-3.4.tar.gz
cd ./tmux-3.4
./configure && make
sudo make install

echo "config tmux"
test -d "$HOME"/.config/tmux || mkdir -p ~/.config/tmux
ln -sf "$HOME"/documents/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm
tmux source "$HOME"/.config/tmux/tmux.conf

echo "install nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

echo "install node 20 18"
# shellcheck disable=SC1091
source "$HOME/.zshrc"
nvm install 20
nvm install 18

echo "install pyenv"
curl https://pyenv.run | bash

echo "install python 3.12.3"
# shellcheck disable=SC1091
source "$HOME/.zshrc"
pyenv install 3.12.3

echo "create nvim venv"
pyenv shell 3.12.3
python -m venv "$HOME"/.nvim-venv

echo "install vscode-js-debug"
git clone https://github.com/microsoft/vscode-js-debug "$HOME"/.dap-js
cd "$HOME"/.dap-js
nvm use
npm install --legacy-peer-deps
npx gulp vsDebugServerBundle
mv dist out
cd "$HOME"

echo "nvim config python and vscode-js-debug"
local_options="$HOME/documents/dotfiles/nvim/lua/config/local-options.lua"
touch "$local_options"
echo 'vim.g.python3_host_prog = os.getenv "HOME" .. "/.nvim-venv/bin/python3"' >>"$local_options"
echo 'vim.g.vscode_js_debug_path = os.getenv "HOME" .. "/.dap-js"' >>"$local_options"
