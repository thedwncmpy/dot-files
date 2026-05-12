# Dotfiles Overview

This repository contains terminal-first development configuration for Ghostty, tmux, zsh, and Neovim.

## Ghostty

Configured in `ghostty/config`.

Ghostty is the terminal emulator. The config uses `Lilex Nerd Font`, 20pt text, a pure black background, balanced padding, a transparent macOS titlebar, saved window state, and Display P3 color.

## tmux

Configured in `tmux/.tmux.conf`.

tmux manages persistent terminal sessions, windows, and panes. The config uses
`C-a` as the prefix, 1-based windows, vi copy mode, true-color support, system
clipboard integration, and focus events for Neovim. New sessions automatically
create `editor`, `ai`, and `server` windows.

Plugins are managed with TPM and include:

- `christoomey/vim-tmux-navigator` for seamless Neovim/tmux navigation
- `catppuccin/tmux` for theming
- `tmux-plugins/tmux-resurrect` for session restoration
- `tmux-plugins/tmux-continuum` for automatic tmux environment support
- `vaaleyard/tmux-dotbar` for the top status bar

## Zsh

Configured in `zshrc/.zshrc`.

zsh is the interactive shell. The config uses Oh My Zsh with Powerlevel10k,
autosuggestions, syntax highlighting, and interactive directory changes.

Notable shell tooling:

- `zoxide` for smarter directory jumping
- `pyenv` for Python version management
- `fzf` for fuzzy search and history selection
- `codex` shell completions
- `nvm` for Node.js version management
- `bat` as an enhanced `cat`
- `lsd` as an enhanced `ls`
- `pnpm` aliases for JavaScript and TypeScript projects
- tmux aliases for common session commands

The shell also auto-activates `.venv` or `venv` Python environments when
entering a project directory and deactivates them when leaving.

## Neovim

Configured from `nvim/init.lua` and `nvim/lua/config/lazy.lua`.

Neovim is a Lua-based editor setup using `lazy.nvim`. The current config is
custom and plugin-driven, with language tooling, formatting, linting, fuzzy
search, Git, file navigation, and tmux integration.

Main Neovim technologies:

- `lazy.nvim` for plugin management
- `nvim-lspconfig` and `mason` for language server setup
- `nvim-cmp` and `LuaSnip` for completion and snippets
- `conform.nvim` for format-on-save with Prettier, Stylua, Black, and isort
- `nvim-lint` for lint-on-save with `eslint_d` and `pylint`
- `telescope.nvim` and `fzf-native` for fuzzy finding
- custom Telescope multi-grep powered by ripgrep
- `nvim-treesitter` for syntax highlighting
- `oil.nvim` for file and directory editing
- `bufferline.nvim`, `lualine.nvim`, and `mini.statusline` for UI/status
- `github-nvim-theme` with black-background customization
- `vim-tmux-navigator` for moving between tmux panes and Neovim splits
- `lazygit.nvim` for Git workflows inside Neovim
- `todo-comments.nvim`, `nvim-surround`, `nvim-autopairs`, `dressing.nvim`,
  and `smear-cursor.nvim` for editing and interface polish

## Workflow Summary

The setup is optimized around a terminal-first development workflow: Ghostty
hosts tmux, tmux manages persistent work sessions, zsh provides fast navigation
and tool aliases, and Neovim is the central editor with LSP, formatting,
linting, fuzzy search, Git, and tmux navigation integrated.
