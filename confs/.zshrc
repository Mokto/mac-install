export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
export HISTTIMEFORMAT="[%F %T] "

setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_FIND_NO_DUPS

eval $(/opt/homebrew/bin/brew shellenv)

eval "$(starship init zsh)"

. $(brew --prefix asdf)/libexec/asdf.sh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

export PATH="${PATH}:$(go env GOPATH)/bin"

alias cat="bat"
alias ls="exa"

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

function killport () {
       kill -9 $(lsof -i:$1 -t) 2> /dev/null
}

source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"


source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
