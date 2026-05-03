return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  -- or                              , branch = '0.1.x',
  dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
  config = function()
    local tele = require("telescope")
    tele.setup({
      pickers = {
        find_files = { theme = "dropdown" },
        live_grep = { theme = "dropdown" },
        buffers = { theme = "dropdown" },
        help_tags = { theme = "dropdown" },
      },
      extensions = {
        fzf = {},
      },
    })

    tele.load_extension("fzf")

    require("config.telescope.multigrep").setup()
    local builtin = require("telescope.builtin")
    -- Narrow the symbol picker to callable members for quick code navigation.
    local function list_document_functions()
      builtin.lsp_document_symbols({
        symbols = { "Function", "Method", "function", "method" },
      })
    end
    vim.keymap.set("n", "<leader>fd", list_document_functions, { desc = "Telescope document functions" })
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
    vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Telescope help tags" })
    -- vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "LSP References" })
  end,
}
