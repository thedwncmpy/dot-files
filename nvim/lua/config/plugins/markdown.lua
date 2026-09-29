-- Configure rendered Markdown headings, checkboxes, and tables.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      heading = {
        -- Use the full window width to avoid clipping heading text in reader mode.
        width = "full",
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
      pipe_table = {
        preset = "round",
      },
    },
  },
}
