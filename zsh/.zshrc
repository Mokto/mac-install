eval "$(starship init zsh)"

. $(brew --prefix asdf)/libexec/asdf.sh
eval $(/opt/homebrew/bin/brew shellenv)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

alias default_branch='git branch -r | grep  "HEAD -> " | sed -e "s/^[[:space:]]*//"  | sed -e "s/^origin\/HEAD -> origin\///" | sed -e "s/^[[:space:]]*//"'
alias current_branch='git rev-parse --abbrev-ref HEAD'
alias gmergebase='git merge-base origin/$(default_branch) $(current_branch)'
alias gs='git rebase -i $(gmergebase)'
alias gp='git push -u origin $(current_branch)'
alias gr='git fetch origin && git rebase origin/$(default_branch)'
alias gc='git checkout' 
alias gcd='git checkout develop && git fetch origin develop && git reset --hard origin/develop'

function glog () {
    git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short
}
# function gco () {
#     local message=$@
#     if [ -z "${message// }" ]
#         then echo "Commit message missing"
#     else
#       # echo "git commit -am '$message'"
#       git commit -m "$message"
#     fi
# }
# function gb () {
#     local branch=$@
#     if [ -z "${branch// }" ]
#         then echo "Branch name missing"
#     else
#       git checkout develop
#       git fetch origin
#       git reset --hard origin/develop
#       git checkout -b "$branch"
#     fi
# }

function killport () {
       kill -9 $(lsof -i:$1 -t) 2> /dev/null
}

source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"

#[[ -s "/Users/theo/.gvm/scripts/gvm" ]] && source "/Users/theo/.gvm/scripts/gvm"

# export PATH="${PATH}:/Users/$USER/go/bin:~/go/bin"

# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"    # if `pyenv` is not already on PATH
# eval "$(pyenv init --path)"
# eval "$(pyenv init -)"