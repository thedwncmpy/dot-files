# ==========================================
# 1. POWERLEVEL10K INSTANT PROMPT
# ==========================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==========================================
# 2. ENVIRONMENT VARIABLES & PATHS
# ==========================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH="$HOME/.oh-my-zsh"
export PYENV_ROOT="$HOME/.pyenv"

# Ensure PATH entries are unique
typeset -U path PATH

# Path setup
path=(
  "$HOME/.pnpm-global/bin"
  "$PYENV_ROOT/bin"
  $path
)

export EDITOR=$(command -v nvim || echo "vi")
export VISUAL=$(command -v nvim || echo "vi")
export FZF_DEFAULT_OPTS="--cycle"
# Load Notion Integration
if [[ -f "$HOME/.config/zshrc/notion/notion.zsh" ]]; then
  source "$HOME/.config/zshrc/notion/notion.zsh"
fi

# ==========================================
# 3. OH-MY-ZSH CONFIGURATION
# ==========================================
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-interactive-cd
)

source $ZSH/oh-my-zsh.sh

# ==========================================
# 4. TOOL INITIALIZATIONS (Zoxide, Pyenv, FZF)
# ==========================================
eval "$(zoxide init zsh)"
eval "$(pyenv init - zsh)"
eval "$(codex completion zsh)"
source <(fzf --zsh)

# Load p10k config if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# ==========================================
# 5. ALIASES
# ==========================================
# General & Navigation
alias c='clear'
alias vs='code .'
alias cd='z'
alias cdi='zi'

# Terminal/Editor (Using Bat & FZF)
alias nv='nvim'
alias cat="bat --color=always"
alias view='fzf'
alias ivs='nvim $(fzf -m --preview="bat --color=always {}")'

# LSD (Modern ls)
alias ls='lsd -F'
alias la='lsd -AF'
alias ll='lsd -lAF'
alias lg='lsd -F --group-dirs=first'
alias tree="lsd -AF --tree --ignore-glob='**/{node_modules,.next,.git}'"

# Git
alias gs='git status'
alias gcm='git commit -m'
alias gp='git push'
alias gpp='git pull'
alias gsa='git add .'
alias gb='git --no-pager branch -a'

# PNPM
alias pinst='pnpm i'
alias pstudio='pnpm db:studio'
alias padd='pnpm add'
alias prun='pnpm run dev'

# TMUX
alias tns='tmux new -s'
alias ta='tmux attach -t'
alias td='tmux detach'
alias tls='tmux ls'

#AI
alias ask="gemini -p"
# ==========================================
# 6. CUSTOM FUNCTIONS & SETTINGS
# ==========================================

# Create a directory and move into it
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}


# Smart PNPM Dev: Runs dev and auto-opens localhost in browser
pdev() {
  local opened=false
  pnpm run dev 2>&1 | while IFS= read -r line; do
    echo "$line"
    if [[ "$opened" == false && "$line" == *"Local:"* && "$line" == *"localhost"* ]]; then
      local url=$(echo "$line" | grep -o 'http://localhost:[0-9]*')
      if [[ -n "$url" ]]; then
        echo "Opening $url"
        open "$url"
        opened=true
      fi
    fi
  done
}

# Lookup documentation
cheat() {
  curl -s "cheat.sh/$1"
}

_cheat_completions() {
  local -a libraries
  # Fetch a list of languages/libraries from cheat.sh and cache them
  libraries=($(curl -s cheat.sh/:list))
  _describe 'command' libraries
}

compdef _cheat_completions cheat

# Auto-activate/deactivate project virtualenvs when moving across directories.
function _auto_activate_venv() {
  # 1. ACTIVATE: If we enter a dir with .venv and it's not already active
  if [[ -d .venv || -d venv ]]; then
    local venv_path=$( [[ -d .venv ]] && echo ".venv" || echo "venv" )

    # Only source if we aren't already in THIS specific venv
    if [[ "$VIRTUAL_ENV" != "$(pwd)/$venv_path" ]]; then
      source "$venv_path/bin/activate"
    fi

  # 2. DEACTIVATE: If a venv is active, but we are no longer in that project
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    # Check if the current working directory is NOT a subfolder of the venv's parent
    local project_dir=$(dirname "$VIRTUAL_ENV")
    if [[ "$PWD" != "$project_dir"* ]]; then
      deactivate
    fi
  fi
}

add-zsh-hook chpwd _auto_activate_venv
_auto_activate_venv
# History Settings
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt appendhistory
setopt histignoredups
setopt incappendhistory

# FZF History Search (Ctrl+R)
fh() {
  # Use fzf to pick from shell history and inject into the command line buffer.
  BUFFER=$(history -n 1 | fzf --height=6 --layout=reverse --info=inline --tac)
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N fh
bindkey '^R' fh

# FZF UI Theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#000000,bg+:#262626
  --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
  --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --layout="reverse" --info="right"
  --preview="bat --color=always --line-range=:500 {}"'

#NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
