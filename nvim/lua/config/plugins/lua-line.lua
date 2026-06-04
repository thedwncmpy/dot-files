return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "SmiteshP/nvim-navic" },
    config = function()
      local iceberg_transparent = require("lualine.themes.iceberg_dark")
      local mode_colors = {
        n = "#3b82f6",
        i = "#22c55e",
        v = "#eab308",
        V = "#eab308",
        ["\22"] = "#eab308",
        R = "#ef4444",
        c = "#f97316",
        t = "#14b8a6",
      }

      for _, mode in pairs(iceberg_transparent) do
        for _, section in pairs(mode) do
          section.bg = nil
        end
        if mode.a then mode.a.fg = "#ffffff" end
        if mode.z then mode.z.fg = "#ffffff" end
      end

      require("lualine").setup {
        options = {
          icons_enabled = true,
          theme = iceberg_transparent,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          always_show_tabline = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
            refresh_time = 16, -- ~60fps
            events = {
              "WinEnter",
              "BufEnter",
              "BufWritePost",
              "SessionLoadPost",
              "FileChangedShellPost",
              "VimResized",
              "Filetype",
              "CursorMoved",
              "CursorMovedI",
              "ModeChanged",
            },
          },
        },
        sections = {
          lualine_a = {
            {
              "mode",
              color = function()
                return {
                  fg = "#ffffff",
                  bg = mode_colors[vim.fn.mode()] or "#3b82f6",
                  gui = "bold",
                }
              end,
            },
          },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename", { "navic", color_correction = "nil" } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {},
      }

      vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
      vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
    end,
  },
}
