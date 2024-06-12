# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=10000
setopt autocd beep nomatch notify
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

export EDITOR='nano'

source ~/.zsh-aliases
source ~/.zsh-functions
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(atuin init zsh)"
#eval "$(atuin init zsh --disable-up-arrow)"



# set promt theme (promt -l, prompt -p)
# Load promptinit
autoload -Uz promptinit && promptinit

# Define the theme
prompt_mytheme_setup () {
  local fadebar_cwd=${1:-'green'}
  local userhost=${2:-'white'}

  local -A schars
  autoload -Uz prompt_special_chars
  prompt_special_chars

  PS1="%F{$fadebar_cwd}%B%K{$fadebar_cwd}$schars[333]$schars[262]$schars[261]$schars[260]%F{$userhost}%K{$fadebar_cwd}%B%n@%m%b%F{$fadebar_cwd}%K{black}$schars[333]$schars[262]$schars[261]$schars[260] $prompt_newline%F{$fadebar_cwd}%K{black}%B%~/%b%k%f "
  PS2="%F{$fadebar_cwd}%K{black}$schars[333]$schars[262]$schars[261]$schars[260]%f%k>"

  prompt_opts=(cr subst percent)
}

# Add the theme to promptsys
prompt_themes+=( mytheme )

# Load the theme
prompt mytheme blue white
