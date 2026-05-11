return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      heading = {
        -- 'block' width often fixes highlight spillover into the gutter/sign column
        width = "block",
        -- 'inline' position can help with rendering consistency during anti-conceal transitions
        position = "inline",
        -- Disable signs in the gutter
        sign = false,
      },
      completions = {
        lsp = {
          enabled = true,
        },
      },
    },
  },
}
