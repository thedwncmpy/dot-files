if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"

if [[ -f "$HOME/.config/zshrc/.zshrc" ]]; then
  source "$HOME/.config/zshrc/.zshrc"
fi
