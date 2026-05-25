return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"

    conform.setup {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        lua = { "stylua" },
        python = { "isort", "black" },
      },
      format_on_save = {
        lsp_fallback = true,
        async = false,
        timeout_ms = 3000,
      },
    }

    vim.keymap.set({ "n", "v", "i" }, "<C-s>", function()
      -- If in Insert mode, escape to Normal mode first
      if vim.api.nvim_get_mode().mode == "i" then
        vim.cmd "stopinsert" -- This is equivalent to pressing <Esc>
      end

      -- 1. Format the file or range
      conform.format {
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      }

      -- 2. Save the file
      vim.cmd "write"

      -- NOTE: The cursor will remain in Normal mode after execution.
      -- If you want to return to Insert mode, you'll need additional logic.
      -- However, since C-s is often used as a save-and-stop-editing command,
      -- staying in Normal mode is usually the desired behavior.
    end, { desc = "Format and Save file or range" })
  end,
}
