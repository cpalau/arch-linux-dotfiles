#!/bin/bash
# ~/.bashrc - Bash configuration for interactive non-login shells
# Part of Arch Linux dotfiles configuration

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
# This section contains all environment variable definitions

# GnuPG Configuration
# Use standard GnuPG directory (symlinked to dotfiles during installation)
export GNUPGHOME="$HOME/.gnupg"

# Editor Configuration
export EDITOR="vim"
export VISUAL="vim"

# History Configuration
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000

# ============================================================================
# SHELL OPTIONS
# ============================================================================
# Bash-specific configuration and behavior

# Append to the history file, don't overwrite it
shopt -s histappend

# Check the window size after each command and update LINES and COLUMNS
shopt -s checkwinsize

# Enable ** globbing pattern
shopt -s globstar

# ============================================================================
# ALIASES
# ============================================================================
# Command shortcuts and customizations

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Basic ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ============================================================================
# COMPLETION
# ============================================================================
# Enable programmable completion features

# Enable bash completion in interactive shells
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ============================================================================
# PROMPT CONFIGURATION
# ============================================================================
# Customize the command prompt (PS1)

# Simple colored prompt showing user@host:path
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '