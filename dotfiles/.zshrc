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
alias -- gcd='git checkout $(default_branch) && git fetch origin $(default_branch) && git reset --hard origin/$(default_branch'
alias -- gmergebase='git merge-base origin/$(default_branch) $(current_branch)'
alias -- gp='git push -u origin $(current_branch)'
alias -- gr='git fetch origin && git rebase origin/$(default_branch)'
alias -- gs='git rebase -i $(gmergebase)'
alias -- gsad='git stash apply stash@{0} && git stash drop stash@{0}'
alias -- gsta='git stash --include-untracked'
alias -- ll='ls -la'
alias -- platforms='zed ~/Projects/platforms'
alias -- code='zed'
alias -- terraform='tofu'

alias -- fixactionrunners='ssh -i ~/Projects/gitops/hetzner-k3s-dc1/id_es25519  -o StrictHostKeyChecking=no root@65.109.75.99 rm -rf /home/runner/_work/platforms/platforms/go && ssh -i ~/Projects/gitops/hetzner-k3s-dc1/id_es25519  -o StrictHostKeyChecking=no root@157.180.52.189 rm -rf /home/runner/_work/platforms/platforms/go'

connect() {
    ssh -i ~/Projects/gitops/hetzner-k3s-dc1/id_es25519 \
        -o StrictHostKeyChecking=no \
        root@"$1"
}


# export KUBECONFIG=/Users/theo/Projects/gitops/hetzner-k3s-dc1/kubeconfig.yaml


export PATH="/opt/homebrew/opt/go@1.23/bin:$PATH"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
