#!/usr/bin/env bash

set -e

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
sudo apt install make gcc ripgrep fd-find unzip git xclip curl wget -y

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
test -d "$HOME"/.config || mkdir -p ~/.config
ln -sf "$HOME"/documents/dotfiles/nvim ~/.config/nvim

echo "install tree-sitter"
if [[ ! -f $HOME/.local/bin/tree-sitter ]]; then
  mkdir -p "$HOME"/.local/bin
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
test -d "$HOME"/.config/tmux || mkdir -p ~/.config/tmux
ln -sf "$HOME"/documents/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
if [[ ! -d $HOME/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm
fi
#tmux source "$HOME"/.config/tmux/tmux.conf

echo "install nvm"
if [[ ! -d $HOME/.nvm ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

echo "install node 20 18"
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 18
nvm install 20

echo "install pnpm"
if [[ ! -d $HOME/.local/share/pnpm ]]; then
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

echo "install uv"
if [[ ! -f $HOME/.local/bin/uv ]]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

read -r -p "Whether to install docker? y or n: " docker
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
