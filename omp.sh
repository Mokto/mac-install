#!/bin/zsh

if ! command -v omp >/dev/null; then
  echo "Installing oh-my-pi (omp)..."
  bun install -g @oh-my-pi/pi-coding-agent
fi

mkdir -p "$HOME/.omp/agent" "$HOME/.omp/agent/extensions"
ln -sfh "$(pwd)/dotfiles/omp/config.yml" "$HOME/.omp/agent/config.yml"
ln -sfh "$(pwd)/dotfiles/omp/user-agents.md" "$HOME/.omp/agent/AGENTS.md"
ln -sfh "$(pwd)/dotfiles/omp/scripts" "$HOME/.omp/scripts"
ln -sfh "$(pwd)/dotfiles/omp/rules" "$HOME/.omp/agent/rules"
for ext in "$(pwd)/dotfiles/omp/extensions"/*/; do
  ext_name="$(basename "${ext%/}")"
  mkdir -p "$HOME/.omp/agent/extensions/$ext_name"
  for file in "$ext"*; do
    [[ -L "$file" ]] && continue
    ln -sfh "$file" "$HOME/.omp/agent/extensions/$ext_name/$(basename "$file")"
  done
done
