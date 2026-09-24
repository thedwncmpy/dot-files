-- Load automatic bracket pairing with the plugin's default settings.
return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    -- Use plugin defaults by delegating to require("nvim-autopairs").setup({}).
    config = true,
  },
}
