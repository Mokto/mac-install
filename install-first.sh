#!/bin/bash

brew install \
    zsh \
    1password \
    google-chrome \
    zsh-completions

brew cask install iterm2   visual-studio-code

brew tap homebrew/cask-fonts
brew cask install font-hack-nerd-font

code --install-extension dbaeumer.vscode-eslint
code --install-extension jpoissonnier.vscode-styled-components
code --install-extension ms-vscode.Go
code --install-extension vscode-icons-team.vscode-icons
code --install-extension whizkydee.material-palenight-theme
code --install-extension EditorConfig.EditorConfig

cp confs/vscode.json ~/Library/Application\ Support/Code/User/settings.json