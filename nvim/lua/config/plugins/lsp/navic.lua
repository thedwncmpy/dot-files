-- Configure LSP breadcrumb context for statusline integrations.
return {
  "SmiteshP/nvim-navic",
  dependencies = { "neovim/nvim-lspconfig" },
  opts = {
    lsp = {
      auto_attach = true,
    },
    highlight = true,
  },
}
