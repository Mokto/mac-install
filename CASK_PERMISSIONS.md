# Avoiding admin rights for Homebrew cask upgrades

Some apps (Chrome, Claude, ChatGPT, etc.) have built-in auto-updaters that update the app bundle as a privileged process, setting ACLs that your user account cannot clear. This causes `brew upgrade` to fail with `Operation not permitted` unless you use `sudo`.

## Solution: install user apps to `~/Applications`

Apps installed in `~/Applications` are owned by your user. No admin is ever needed to upgrade them, and self-updaters also write there without elevated permissions.

## Setup

### 1. Split your Brewfile

**`Brewfile`** — formulae and casks that need `/Applications` (system drivers, apps with deep OS integration):
```
cask "displaylink"   # system driver
cask "fastmail"      # needs /Applications for mailto: handler
cask "zed"           # needs /Applications for CLI integration
```

**`Brewfile.apps`** — regular user apps:
```
cask "google-chrome"
cask "claude"
cask "chatgpt"
...
```

### 2. Set the default appdir

Add to `~/.zshrc`:
```zsh
export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
```

This makes `brew install --cask` default to `~/Applications` for all future installs.

### 3. Install script

`install.sh` runs both bundles with the right appdir:
```zsh
mkdir -p "$HOME/Applications"

brew bundle --file Brewfile
HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" brew bundle --file Brewfile.apps
```

### 4. Migrate an existing machine

If apps are already installed in `/Applications`, run:
```bash
./bin/reinstall-casks.sh
```

This reinstalls all casks from `Brewfile.apps` to `~/Applications`. System casks (`displaylink`, `fastmail`, `zed`) are skipped.

## Deciding where a cask goes

Put a cask in `Brewfile` (→ `/Applications`) if it:
- Installs a system driver or kernel extension
- Registers a URL/mailto handler that only works from `/Applications`
- Provides a CLI that expects the app at a fixed system path

Put it in `Brewfile.apps` (→ `~/Applications`) otherwise.

## Fixing a broken cask

If an app ends up in the wrong place or has a corrupt state:
```bash
sudo rm -rf /Applications/App.app ~/Applications/App.app /opt/homebrew/Caskroom/<cask>
HOMEBREW_CASK_OPTS="--appdir=/Applications" brew install --cask <cask>  # for system casks
brew install --cask <cask>                                               # for user casks
```
