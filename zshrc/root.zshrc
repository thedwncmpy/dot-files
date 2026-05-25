if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [[ -f "$HOME/.config/zshrc/.zshrc" ]]; then
  source "$HOME/.config/zshrc/.zshrc"
fi
