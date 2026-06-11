# Enable Powerlevel10k instant prompt (must stay near the top, before any output)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

zstyle ':zim:zmodule' use 'degit'

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi

source ${ZIM_HOME}/init.zsh

HISTFILE=~/.customhistory
HISTSIZE=500000
SAVEHIST=500000
setopt appendhistory
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY


alias -- current_branch='git rev-parse --abbrev-ref HEAD'
alias -- default_branch='git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed "s@^refs/remotes/origin/@@" || git branch -r | grep -E "origin/(main|master)" | head -1 | sed "s/.*origin\///" | tr -d " "'
alias -- gc='git checkout'
alias -- gcd='git checkout main && git fetch origin main && git reset --hard origin/$(default_branch)'
alias -- gmergebase='git merge-base origin/main $(current_branch)'
alias -- gp='git push -u origin $(current_branch)'
alias -- gr='git fetch origin && git rebase origin/main'
alias -- gs='git rebase -i $(gmergebase)'
alias -- gsad='git stash apply stash@{0} && git stash drop stash@{0}'
alias -- gsta='git stash --include-untracked'
alias -- ll='eza -la --icons --git'
alias -- l='eza -l --icons --git'
alias -- lt='eza --tree --icons --git-ignore'
alias -- cat='bat --paging=never'
alias -- platforms='zed ~/Projects/platforms'
alias -- code='zed'
alias -- terraform='tofu'

alias -- fixactionrunners='ssh -i ~/Projects/gitops/hetzner-k3s-dc1/id_es25519  -o StrictHostKeyChecking=no root@65.109.75.99 rm -rf /home/runner/_work/platforms/platforms/go && ssh -i ~/Projects/gitops/hetzner-k3s-dc1/id_es25519  -o StrictHostKeyChecking=no root@157.180.52.189 rm -rf /home/runner/_work/platforms/platforms/go'

connect() {
    ssh -i ~/Projects/gitops/hetzner-k3s-dc1/id_es25519 \
        -o StrictHostKeyChecking=no \
        root@"$1"
}


[ -f "$HOME/.mac-install.env" ] && source "$HOME/.mac-install.env"

export KUBECONFIG=$HOME/Ocean/kubeconfig.yaml

export PATH="$HOME/go/bin:$PATH"
export PATH="/opt/homebrew/opt/go@1.26/bin:$PATH"
export PATH="/opt/homebrew/opt/node@24/bin:$PATH"
export PATH="$MAC_INSTALL_DIR/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"

export GOOGLE_CLOUD_PROJECT_ID=oceanio-production

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# orbstack
export PATH="$HOME/.orbstack/bin:$PATH"

# rights
export HOMEBREW_CASK_OPTS="--appdir=~/Applications"

# fzf — fuzzy finder (Ctrl+R history, Ctrl+T file picker, Alt+C cd)
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
source <(fzf --zsh) 2>/dev/null

# zoxide — smarter cd (z <partial-dir-name>)
eval "$(zoxide init zsh)"

# Load p10k config (run `p10k configure` to set up or reconfigure)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
