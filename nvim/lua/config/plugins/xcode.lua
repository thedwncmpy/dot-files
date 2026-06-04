return {
  "wojciech-kulik/xcodebuild.nvim",
  ft = { "swift", "objc", "objcpp" },
  cmd = {
    "XcodebuildSetup",
    "XcodebuildSelectScheme",
    "XcodebuildSelectDevice",
    "XcodebuildBuild",
    "XcodebuildBuildRun",
    "XcodebuildProjectManager",
  },
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("xcodebuild").setup({
      test_search = {
        lsp_client = "sourcekit_lsp",
      },
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "XcodebuildProjectSettingsUpdated",
      callback = function()
        for _, client in ipairs(vim.lsp.get_clients({ name = "sourcekit_lsp" })) do
          vim.lsp.stop_client(client.id)
        end

        vim.defer_fn(function()
          vim.cmd("edit")
        end, 100)
      end,
    })
  end,
}
