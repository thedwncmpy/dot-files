return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "ts_ls",
        "lua_ls",
        "bashls",
        "biome",
        "html",
        "cssls",
        "tailwindcss",
        "emmet_ls",
        "prismals",
        "pyright",
        "gopls",
      },
      automatic_installation = true,
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },
}
