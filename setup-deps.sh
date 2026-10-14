#!/usr/bin/env bash
set -euo pipefail

# Homebrew is expected to already be installed.
if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is not installed. Install Homebrew first: https://brew.sh"
  exit 1
fi

# Add a Homebrew tap only when it is missing.
ensure_tap() {
  # Add a Homebrew tap only if it is not already configured.
  local tap="$1"
  if ! brew tap | grep -qx "$tap"; then
    echo "Tapping $tap"
    brew tap "$tap"
  fi
}

install_formulae() {
  # Install the command-line packages used by the dotfiles.
  local formulae=(
    neovim
    tmux
    tpm
    git
    node
    ripgrep
    fd
    fzf
    bat
    lsd
    zoxide
    pyenv
    nvm
    pnpm
    gemini-cli
    lazygit
    lua-language-server
    stylua
    prettier
    eslint_d
    shfmt
    black
    isort
    pylint
  )

  for pkg in "${formulae[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      echo "[ok] $pkg already installed"
    else
      echo "Installing $pkg"
      brew install "$pkg"
    fi
  done
}

install_casks() {
  # Install GUI apps and fonts used by the configuration.
  local casks=(
    ghostty
    font-lilex-nerd-font
    nikitabobko/tap/aerospace
    codex
  )

  for cask in "${casks[@]}"; do
    if brew list --cask "$cask" >/dev/null 2>&1; then
      echo "[ok] $cask already installed"
    else
      echo "Installing $cask"
      brew install --cask "$cask"
    fi
  done
}

install_local_formula() {
  local formula="$1"
  local package="$2"

  if [[ ! -f "$formula" ]]; then
    echo "[skip] $package formula not found at $formula"
    return
  fi

  if brew list --formula "$package" >/dev/null 2>&1; then
    echo "[ok] $package already installed"
  else
    echo "Installing $package from $formula"
    brew install "$formula"
  fi
}

# Install Oh My Zsh plus theme/plugins used by this config.
install_oh_my_zsh_stack() {
  local ohmyzsh_dir="$HOME/.oh-my-zsh"
  local custom_dir="${ZSH_CUSTOM:-$ohmyzsh_dir/custom}"

  if [[ ! -d "$ohmyzsh_dir" ]]; then
    echo "Installing Oh My Zsh"
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "[ok] Oh My Zsh already installed"
  fi

  mkdir -p "$custom_dir/plugins" "$custom_dir/themes"

  if [[ ! -d "$custom_dir/themes/powerlevel10k" ]]; then
    echo "Installing powerlevel10k theme"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom_dir/themes/powerlevel10k"
  else
    echo "[ok] powerlevel10k already installed"
  fi

  if [[ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
    echo "Installing zsh-autosuggestions"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions"
  else
    echo "[ok] zsh-autosuggestions already installed"
  fi

  if [[ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]]; then
    echo "Installing zsh-syntax-highlighting"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/plugins/zsh-syntax-highlighting"
  else
    echo "[ok] zsh-syntax-highlighting already installed"
  fi

  if [[ ! -d "$custom_dir/plugins/zsh-interactive-cd" ]]; then
    echo "Installing zsh-interactive-cd"
    git clone --depth=1 https://github.com/changyuheng/zsh-interactive-cd.git "$custom_dir/plugins/zsh-interactive-cd"
  else
    echo "[ok] zsh-interactive-cd already installed"
  fi
}

# Print post-install actions that still require user interaction.
print_follow_up() {
  cat <<MSG

Done. Next steps:
1. Symlink your config files into place if you haven't already.
2. Start tmux and install TPM plugins with: prefix + I
3. Run nvim once so lazy.nvim/mason can finish plugin and LSP setup.
4. Restart your shell, then install a Node.js LTS version with: nvm install --lts

Note: install the local CLI repositories under ~/dev before running this script if they are missing.
MSG
}

# Run full dependency setup in a predictable order.
main() {
  # Run dependency setup in order, then print the remaining manual steps.
  ensure_tap nikitabobko/tap
  brew update
  install_formulae
  install_local_formula "$HOME/dev/ns-cli/Formula/ns.rb" ns
  install_local_formula "$HOME/dev/tmux-oil/Formula/tmux-oil.rb" tmux-oil
  install_casks
  mkdir -p "$HOME/.nvm"
  install_oh_my_zsh_stack
  print_follow_up
}

main "$@"
