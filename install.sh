#!/bin/bash

# install 1password
# install xcode

brew cask install \
    google-chrome \
    visual-studio-code \
    iterm2 \
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
    zsh \
    zsh-completions \
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

./mac-settings.sh


gpg --full-generate-key

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
