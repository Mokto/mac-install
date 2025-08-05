
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source /opt/homebrew/opt/zimfw/share/zimfw.zsh init
  echo "Inited zimfw..."
fi
source ${ZIM_HOME}/init.zsh

HISTFILE=~/.customhistory
HISTSIZE=500000
SAVEHIST=500000
setopt appendhistory
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY


alias -- current_branch='git rev-parse --abbrev-ref HEAD'
alias -- default_branch='git branch -r | grep "HEAD -> " | sed -e "s/^[[:space:]]*//"  | sed -e "s/^origin\/HEAD -> origin\///" | sed -e "s/^[[:space:]]*//"'
alias -- gc='git checkout'
alias -- gcd='git checkout develop && git fetch origin develop && git reset --hard origin/develop'
alias -- gmergebase='git merge-base origin/$(default_branch) $(current_branch)'
alias -- gp='git push -u origin $(current_branch)'
alias -- gr='git fetch origin && git rebase origin/$(default_branch)'
alias -- gs='git rebase -i $(gmergebase)'
alias -- gsad='git stash apply stash@{0} && git stash drop stash@{0}'
alias -- gsta='git stash --include-untracked'
alias -- ll='ls -la'



export KUBECONFIG=/Users/theo/Projects/gitops/hetzner-k3s-dc1/kubeconfig.yaml


export PATH="/opt/homebrew/opt/go@1.23/bin:$PATH"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
