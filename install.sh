#!/bin/bash

brew cask install \
    1password \
    google-chrome \
    slack \
    spotify \
    firefox \
    java \
    docker \
    rambox \
    vlc \
    plex-media-player \
    insomnia \
    telegram \
    gpg-suite \
    robo-3t \
    ngrok \
    postman

brew tap homebrew/cask-drivers
brew cask install logitech-options

brew install  \
    coreutils \
    rbenv \
    vault \
    awscli \
    kubernetes-cli \
    kubernetes-helm \
    go

brew tap homebrew/cask-fonts
brew cask install font-hack-nerd-font

# RUBY + BUNDLER
brew install rbenv
eval "$(rbenv init -)"
rbenv install $(rbenv install -l | grep -v - | tail -1)
rbenv global $(rbenv install -l | grep -v - | tail -1)
gem install bundler
gem install cocoapods
gem install fastlane -NV

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 12

./utils/mac-settings.sh

echo "Git name ?"
read name

echo "Git email ?"
read email


git config --global user.email $email
git config --global user.name "$name" 
echo "Done"



gpg --full-generate-key
git config --global gpg.program /usr/local/MacGPG2/bin/gpg2
git config --global commit.gpgsign true 

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen
    echo '----------------------'
    echo '----PUBLIC KEY SSH----'
    echo '----------------------'
    cat ~/.ssh/id_rsa.pub
    echo '----------------------'
    echo '----PUBLIC KEY SSH----'
    echo '----------------------'
fi


pod setup
