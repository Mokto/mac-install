#!/bin/bash


GPG_SIGNING_KEY=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}'  | cut -c 9-)
# if empty
if [ -z "$GPG_SIGNING_KEY" ]; then
  echo "No GPG key found. Generating a new key..."
  gpg --full-generate-key
  git config --global gpg.program /usr/local/MacGPG2/bin/gpg2
  git config --global commit.gpgsign true
  git config --global user.signingkey $GPG_SIGNING_KEY

  GPG_KEY=$(gpg --armor --export "$GPG_SIGNING_KEY")

  read -rsp "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
  curl -H "Authorization: token $GITHUB_TOKEN" \
   -X POST https://api.github.com/user/gpg_keys \
   -H "Content-Type: application/json" \
   -d "$(jq -n --arg key "$GPG_KEY" '{armored_public_key: $key}')"

fi


git config --global core.editor "nano"
