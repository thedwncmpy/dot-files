-- Configure filetype-specific linters and run them after each save.
return {
  "mfussenegger/nvim-lint",
  -- Change the event to only load the plugin when a buffer is read/created
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local augroup = vim.api.nvim_create_augroup("LinterOnSave", { clear = true })

    -- 1. Define linters per filetype
    lint.linters_by_ft = {
      python = { "pylint" },
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
    }

    ---

    -- 2. Create the autocommand to run on save
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = augroup,
      desc = "Run linters after file save",
      callback = function()
        -- This calls the linters defined in `linters_by_ft` for the current filetype
        lint.try_lint()
      end,
    })
  end,
}
