#!/bin/bash

# install 1password
# install xcode

brew cask install \
    google-chrome \
    visual-studio-code \
    iterm2 \
    # slack \
    spotify \
    # wavebox \
    jdownloader \
    firefox \
    java \
    docker \
    android-studio \
    the-unarchiver \
    rambox \
    vlc


brew install  \
    coreutils \
    rbenv \
    zsh \
    zsh-completions

# RUBY + BUNDLER
brew install rbenv
eval "$(rbenv init -)"
rbenv install $(rbenv install -l | grep -v - | tail -1)
rbenv global $(rbenv install -l | grep -v - | tail -1)
gem install bundler
gem install cocoapods
pod setup

brew install yarn --without-node

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 10

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen
    echo '------------------'
    echo '----PUBLIC KEY----'
    echo '------------------'
    cat ~/.ssh/id_rsa.pub
    echo '------------------'
    echo '----PUBLIC KEY----'
    echo '------------------'
fi

./mac-settings.sh