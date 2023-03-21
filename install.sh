#!/bin/bash


testcmd () {
    command -v "$1" >/dev/null
}

echo "Git name ?"
read name

echo "Git email ?"
read email

sudo spctl --master-disable

sudo cp fonts/CascadiaCodePL.ttf ~/Library/Fonts/
sudo cp "fonts/Caskaydia Cove Regular Nerd Font Complete.otf" ~/Library/Fonts/

brew install zsh-autosuggestions zsh-syntax-highlighting starship
brew install visual-studio-code 1password google-chrome gpg-suite fig hyper raycast --cask

code --install-extension dbaeumer.vscode-eslint
code --install-extension styled-components.vscode-styled-components
code --install-extension vscode-icons-team.vscode-icons
code --install-extension whizkydee.material-palenight-theme
code --install-extension EditorConfig.EditorConfig
code --install-extension eamodio.gitlens
code --install-extension zxh404.vscode-proto3
code --install-extension silvenon.mdx
code --install-extension stylelint.vscode-stylelint
code --install-extension usernamehw.errorlens
code --install-extension golang.go
code --install-extension ms-python.python

git config --global user.email $email
git config --global user.name "$name" 
echo "Done"


gpg --full-generate-key
git config --global gpg.program /usr/local/MacGPG2/bin/gpg2
git config --global commit.gpgsign true 
git config --global core.editor "nano"

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen
fi

brew tap ferdium/ferdium

brew install \
    slack \
    spotify \
    firefox \
    docker \
    notion \
    ngrok \s
    postman \
    ferdium-nightly \
    zoom \
    karabiner-elements \
    google-cloud-sdk \
    linear-linear \
    iterm2 \
    tunnelblick --cask

brew install  \
    kubernetes-cli \
    jq \
    pulumi \
    openjdk \
    asdf \
    bat \
    exa \
    ripgrep \
    protobuf \
    openjdk@11

sudo ln -sfn $(brew --prefix)/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk

./install-config.sh

source $(brew --prefix asdf)/libexec/asdf.sh
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs latest
asdf global nodejs latest

asdf plugin-add python
asdf install python latest
asdf global python latest

asdf plugin-add golang
asdf install golang latest
asdf global golang latest

asdf plugin-add poetry https://github.com/asdf-community/asdf-poetry.git
asdf install poetry latest
asdf global poetry latest

asdf plugin-add pnpm
asdf install pnpm latest
asdf global pnpm latest

if ! testcmd cargo; then
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi



source $(brew --prefix asdf)/libexec/asdf.sh

npm install -g rebase-editor
git config --global sequence.editor rebase-editor
npm i -g npm-check-updates

brew install --cask hpedrorodrigues/tools/dockutil

./utils/dock-icons.sh

open confs/material-design-colors.itermcolors



