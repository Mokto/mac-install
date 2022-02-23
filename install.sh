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


brew cask install \
    slack \
    spotify \
    firefox \
    docker \
    rambox \
    vlc \
    telegram \
    ngrok \
    whatsapp \
    postman \
    tunnelblick \
    openjdk

# sudo ln -sfn $(brew --prefix)/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk

brew tap homebrew/cask-drivers
brew cask install logitech-options
brew cask install google-cloud-sdk

brew install  \
    kubernetes-cli \
    kubernetes-helm \
    go \
    mercurial \
    jq \
    pulumi

# GOLANG

# zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
# [[ -s "/Users/theo/.gvm/scripts/gvm" ]] && source "/Users/theo/.gvm/scripts/gvm"
# gvm install go1.15 --with-protobuf

# NodeJS
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 14

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


