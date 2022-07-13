#!/bin/bash

sudo cp fonts/CascadiaCodePL.ttf ~/Library/Fonts/
sudo cp "fonts/Caskaydia Cove Regular Nerd Font Complete.otf" ~/Library/Fonts/

cp -f ./confs/.zshrc ~/.zshrc
cp ./confs/.hyper.js ~/.hyper.js
mkdir -p ~/.config && cp ./confs/starship.toml ~/.config/starship.toml
cp confs/vscode.json ~/Library/Application\ Support/Code/User/settings.json
