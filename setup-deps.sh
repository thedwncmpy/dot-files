#!/usr/bin/env bash
set -euo pipefail

if [[ "${OSTYPE:-}" == darwin* ]]; then
  echo "This branch is for Linux. Use the main branch for macOS."
  exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
  echo "Error: this setup script currently supports Fedora/dnf only."
  exit 1
fi

DNF_REPO_FLAGS=()
if dnf repolist --enabled | awk '{print $1}' | grep -qx tailscale-stable; then
  DNF_REPO_FLAGS+=(--disablerepo=tailscale-stable)
fi

install_fedora_packages() {
  local packages=(
    zsh
    git
    curl
    jq
    tmux
    neovim
    ripgrep
    fd-find
    fzf
    bat
    lsd
    zoxide
    python3
    python3-pip
    python3-virtualenv
    make
    gcc
    gcc-c++
    unzip
    nodejs
    npm
    pnpm
    black
    isort
    pylint
    shfmt
    xdg-utils
  )

  sudo dnf "${DNF_REPO_FLAGS[@]}" install -y "${packages[@]}"
}

install_optional_dnf_package() {
  local package="$1"
  local fallback="$2"

  if dnf "${DNF_REPO_FLAGS[@]}" list --available "$package" >/dev/null 2>&1; then
    sudo dnf "${DNF_REPO_FLAGS[@]}" install -y "$package"
  else
    printf '\nNote: %s is not available in the enabled Fedora repositories.\n%s\n' "$package" "$fallback"
  fi
}

clone_or_skip() {
  local repo="$1"
  local dest="$2"

  if [[ -d "$dest" ]]; then
    echo "[ok] $dest already exists"
  else
    git clone --depth=1 "$repo" "$dest"
  fi
}

install_oh_my_zsh_stack() {
  local ohmyzsh_dir="$HOME/.oh-my-zsh"
  local custom_dir="${ZSH_CUSTOM:-$ohmyzsh_dir/custom}"

  clone_or_skip https://github.com/ohmyzsh/ohmyzsh.git "$ohmyzsh_dir"
  mkdir -p "$custom_dir/plugins" "$custom_dir/themes"

  clone_or_skip https://github.com/romkatv/powerlevel10k.git "$custom_dir/themes/powerlevel10k"
  clone_or_skip https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions"
  clone_or_skip https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/plugins/zsh-syntax-highlighting"
  clone_or_skip https://github.com/changyuheng/zsh-interactive-cd.git "$custom_dir/plugins/zsh-interactive-cd"
}

install_tpm() {
  mkdir -p "$HOME/.tmux/plugins"
  clone_or_skip https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}

print_follow_up() {
  cat <<'MSG'

Done. Next steps:
1. Symlink or copy repo configs into ~/.config.
2. Point ~/.zshrc at ~/.config/zshrc/.zshrc, or copy zshrc/root.zshrc to ~/.zshrc.
3. Start tmux and install TPM plugins with: prefix + I
4. Run nvim once so lazy.nvim and mason can finish plugin/LSP setup.
5. Switch login shell if needed: chsh -s /usr/bin/zsh

Optional tools not installed by this script:
- pyenv
- nvm
- Antigravity CLI
- Notion secrets file
MSG
}

main() {
  install_fedora_packages
  install_optional_dnf_package ghostty "Enable a Ghostty COPR or install Ghostty from its official Linux packages."
  install_optional_dnf_package lazygit "Install it through your preferred COPR or with: go install github.com/jesseduffield/lazygit@latest"
  install_oh_my_zsh_stack
  install_tpm
  print_follow_up
}

main "$@"
