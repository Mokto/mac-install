# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# NVM 
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#RUBY
eval "$(rbenv init -)"

export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"

# Customize to your needs...
# https://github.com/bhilburn/powerlevel9k#customizing-prompt-segments
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_DISABLE_RPROMPT=true

cat ~/.env | while read line; do
    export $line
done

export GPG_TTY=$(tty)

alias current_branch='git rev-parse --abbrev-ref HEAD'
alias gmergebase='git merge-base origin/develop $(current_branch)'
alias gs='git rebase -i $(gmergebase)'
alias gp='git push -u origin $(current_branch)'
alias gr='git fetch origin && git rebase origin/develop'
alias gc='git checkout' 

function glog () {
    git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short
}
function gco () {
    local message=$@
    if [ -z "${message// }" ]
        then echo "Commit message missing"
    else
      # echo "git commit -am '$message'"
      git commit -m "$message"
    fi
}
function gb () {
    local branch=$@
    if [ -z "${branch// }" ]
        then echo "Branch name missing"
    else
      git checkout develop
      git fetch origin
      git reset --hard origin/develop
      git checkout -b "$branch"
    fi
}

# createVaultUser () {
#   vault write auth/userpass/users/$1 \
#     password=$2
# }
source '$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'
source '$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'