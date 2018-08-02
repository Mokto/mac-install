#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

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

alias current_branch='git rev-parse --abbrev-ref HEAD'
alias gmergebase='git merge-base origin/develop $(current_branch)'
alias gr='git rebase -i $(gmergebase)'
alias gp='git push -u origin $(current_branch)'