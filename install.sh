#!/bin/bash

# install 1password
# install xcode

brew cask install \
    google-chrome \
    visual-studio-code \
    iterm2 \
    slack \
    spotify \
    wavebox \
    jdownloader \
    firefox \
    java \
    android-studio

brew install  \
    coreutils \
    nvm \
    zsh \
    zsh-completions

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