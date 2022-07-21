#!/bin/bash
cp -f ./confs/.zshrc ~/.zshrc
cp ./confs/.hyper.js ~/.hyper.js
mkdir -p ~/.config && cp ./confs/starship.toml ~/.config/starship.toml
cp confs/vscode.json ~/Library/Application\ Support/Code/User/settings.json
