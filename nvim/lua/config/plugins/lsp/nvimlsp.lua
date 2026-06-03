return {
  "hrsh7th/cmp-nvim-lsp",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "folke/lazydev.nvim", opts = {} },
  },
  config = function()
    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    vim.lsp.config("*", {
      capabilities = capabilities,
    })

    vim.lsp.config("bashls", {
      filetypes = { "sh", "bash", "zsh" },
    })

    vim.lsp.config("gopls", {
      filetypes = { "go", "gomod", "gowork", "gotmpl" },
    })

    vim.lsp.config("sourcekit_lsp", {
      cmd = { "sourcekit-lsp" },
      filetypes = { "swift", "objective-c", "objective-cpp" },
    })

    vim.lsp.enable {
      "lua_ls",
      "ts_ls",
      "biome",
      "html",
      "cssls",
      "tailwindcss",
      "emmet_ls",
      "prismals",
      "pyright",
      "bashls",
      "gopls",
      "sourcekit_lsp",
    }
  end,
}
