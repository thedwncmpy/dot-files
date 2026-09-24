-- Load snippets written in SnipMate format from the Neovim config directory.
return {
  {
    "L3MON4D3/LuaSnip",
    opts = function()
      -- Register the local snippet directory with LuaSnip's SnipMate loader.
      require("luasnip.loaders.from_snipmate").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })
    end,
  },
}
