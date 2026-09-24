-- Configure and load the GitHub Dark theme with transparent sidebars and floats.
return {
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    lazy = false,
    priority = 1000,
    config = function()
      require('github-theme').setup({
        options = {
          transparent = true,
          styles = {
            sidebars = "transparent",
            floats = "transparent",
          },
          darken = {
            sidebars = { "qf", "vista_kind", "terminal", "packer" },
            floats = true,
          },
        },
      })

      vim.cmd('colorscheme github_dark_default')
    end,
  }
}
