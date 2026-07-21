return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require "conform"

    local function markdown_format_enabled(bufnr)
      return vim.bo[bufnr].filetype ~= "markdown" or vim.b[bufnr].markdown_format_enabled == true
    end

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
        zsh = { "shfmt" },
        lua = { "stylua" },
        python = { "isort", "black" },
      },
      format_on_save = function(bufnr)
        if not markdown_format_enabled(bufnr) then return nil end
        return {
          lsp_fallback = true,
          async = false,
          timeout_ms = 3000,
        }
      end,
    }

    vim.api.nvim_create_user_command("MarkdownFormatToggle", function()
      vim.b.markdown_format_enabled = not vim.b.markdown_format_enabled
      local state = vim.b.markdown_format_enabled and "enabled" or "disabled"
      vim.notify("Markdown formatting " .. state .. " for this buffer")
    end, { desc = "Toggle Markdown formatting for the current buffer" })

    vim.keymap.set("n", "<leader>mf", "<cmd>MarkdownFormatToggle<CR>", { desc = "Toggle Markdown formatting" })

    vim.keymap.set({ "n", "v", "i" }, "<C-s>", function()
      -- If in Insert mode, escape to Normal mode first
      if vim.api.nvim_get_mode().mode == "i" then
        vim.cmd "stopinsert" -- This is equivalent to pressing <Esc>
      end

      -- 1. Format the file or range
      if markdown_format_enabled(0) then
        conform.format {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        }
      end

      -- 2. Save the file
      vim.cmd "write"

      -- NOTE: The cursor will remain in Normal mode after execution.
      -- If you want to return to Insert mode, you'll need additional logic.
      -- However, since C-s is often used as a save-and-stop-editing command,
      -- staying in Normal mode is usually the desired behavior.
    end, { desc = "Format and Save file or range" })
  end,
}
