#!/bin/bash

GPG_SIGNING_KEY=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}'  | cut -c 9-)

echo "FOUND $GPG_SIGNING_KEY"

git config --global user.signingkey $GPG_SIGNING_KEY 

echo "Git is now set up with GPG."

gpg --armor --export $GPG_SIGNING_KEY | pbcopy

echo "GPG public key copied."
