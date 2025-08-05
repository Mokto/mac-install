




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