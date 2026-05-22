return {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    -- Add the keymaps here
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next todo comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous todo comment",
      },
      {
        "<leader>fn", -- This binds the command to <Leader>fn (e.g., <Space>fn)
        "<cmd>TodoTelescope<cr>",
        desc = "Find [n]ame/Todo comments",
        mode = "n", -- Normal mode
      },
    },
  },
}
