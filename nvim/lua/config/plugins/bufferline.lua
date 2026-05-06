return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          show_tab_indicators = false,
          show_buffer_close_icons = false,
          show_close_icon = false,
          modified_icon = "",
          indicator = {
            icon = "",
            style = "icon",
          },
        },
        highlights = {
          fill = {
            bg = "NONE",
          },
          background = {
            bg = "NONE",
          },
          buffer_visible = {
            bg = "NONE",
          },
          separator = {
            bg = "NONE",
          },
          separator_visible = {
            bg = "NONE",
          },
          tab = {
            bg = "NONE",
          },
          buffer_selected = {
            bg = "#141414",
            bold = true,
            italic = false,
          },
          modified = {
            bg = "NONE",
          },
          modified_visible = {
            bg = "NONE",
          },
          modified_selected = {
            bg = "#141414",
          },
          separator_selected = {
            bg = "#141414",
          },
        },
      })

      -- Keep the tabline surface transparent outside the selected buffer.
      vim.api.nvim_set_hl(0, "TabLine", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })

      -- Extra bufferline groups that can still paint a background in some themes.
      vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "BufferLineSeparator", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "BufferLineTab", { bg = "NONE" })
    end,
  },
}
