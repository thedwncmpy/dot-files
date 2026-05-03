return {
  {
    "echasnovski/mini.nvim",
    config = function()
      -- Enable mini.nvim's statusline with icon support.
      local statusline = require "mini.statusline"
      statusline.setup { use_icons = true }
    end,
  },
}
