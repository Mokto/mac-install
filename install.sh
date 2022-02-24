#!/bin/bash


echo "Git name ?"
read name

echo "Git email ?"
read email


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
    vlc \
    ngrok \
    whatsapp \
    postman \
    ferdi \
    zoom \
    tunnelblick --cask

# sudo ln -sfn $(brew --prefix)/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk

brew install google-cloud-sdk --cask

brew install  \
    kubernetes-cli \
    kubernetes-helm \
    go \
    mercurial \
    jq \
    pulumi \
    openjdk

# NodeJS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 16

curl https://pyenv.run | bash

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

killall Dock

./utils/dock-icons.sh


# TODO
# pod setup


open confs/material-design-colors.itermcolors



