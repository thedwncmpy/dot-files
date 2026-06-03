return {
  "wojciech-kulik/xcodebuild.nvim",
  ft = { "swift", "objc", "objcpp" },
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("xcodebuild").setup({})
  end,
}
