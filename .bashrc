# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Enable bash-completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi


# Ensure .bash_history exists and is a file
if [ ! -f ~/.bash_history ]; then
    touch ~/.bash_history
fi

# History Settings
HISTCONTROL=ignoreboth:ignorespace:ignoredups
HISTTIMEFORMAT="%d/%m/%y %T "
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Shell Options
shopt -s checkwinsize
# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar


# PS1 configuration:
# \[\033[01;33m\] - Sets bright yellow color
# \u - Username
# @ - Literal @
# \h - Hostname
# \[\033[00m\] - Resets color
# \[\033[01;34m\] - Sets bright blue color
# \w - Current working directory (full path)
# $(git_branch) - Calls git_branch function to show current branch if in a git repo
# \$ - Shows $ for regular users, # for root
# Space at the end for separation from commands
PS1='\[\033[01;33m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]$(git_branch)\[\033[00m\]\$ \[\033[00m\]'

# Git Prompt Customization
git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Environment Setup
# export EDITOR="nano" # Set default editor
export CHEATCOLORS="true"
export ANSIBLE_CONFIG=~/.ansible.cfg
