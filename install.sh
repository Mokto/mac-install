#!/bin/bash


echo "Git name ?"
read name

echo "Git email ?"
read email

sudo spctl --master-disable

cp -f ./zsh/.zshrc ~/.zshrc

sudo cp CascadiaCodePL.ttf /Library/Fonts/

brew install zsh-autosuggestions starship iterm2 visual-studio-code 1password google-chrome gpg-suite --cask

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

cp confs/vscode.json ~/Library/Application\ Support/Code/User/settings.json

git config --global user.email $email
git config --global user.name "$name" 
echo "Done"


# gpg --full-generate-key
# git config --global gpg.program /usr/local/MacGPG2/bin/gpg2
# git config --global commit.gpgsign true 

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen
fi


brew install \
    slack \
    spotify \
    firefox \
    docker \
    notion \
    ngrok \
    whatsapp \
    postman \
    ferdium-nightly \
    zoom \
    karabiner-elements \
    google-cloud-sdk \
    dockutil \
    tunnelblick --cask

brew install  \
    kubernetes-cli \
    kubernetes-helm \
    jq \
    pulumi \
    openjdk \
    asdf

$(brew --prefix asdf)/libexec/asdf.sh
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin-add python
asdf plugin-add golang
asdf install nodejs latest
asdf install python latest
asdf install golang latest
asdf global nodejs latest
asdf global python latest
asdf global golang latest


npm install -g rebase-editor
git config --global sequence.editor rebase-editor
npm i -g npm-check-updates

./utils/mac-settings.sh

# Docker
defaults write com.apple.dock tilesize -int 50
defaults write com.apple.dock autohide -bool false
# key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 12
# Hot corners
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true


./utils/dock-icons.sh

open confs/material-design-colors.itermcolors



