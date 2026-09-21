return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      preview_win = {
        -- Keep the real filename so image.nvim can hijack the preview buffer.
        preview_method = "load",
      },
      keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["<C-s>"] = false,
        ["<C-h>"] = false,
        ["<leader>v"] = { "actions.select", opts = { vertical = true } },
        ["<leader>h"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["<C-l>"] = "actions.refresh",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = { "actions.cd", mode = "n" },
        ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["g\\"] = { "actions.toggle_trash", mode = "n" },
      },
    },
    -- Optional dependencies
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      {
        "3rd/image.nvim",
        opts = {
          -- Ghostty supports Kitty graphics locally and over SSH; tmux is
          -- configured with passthrough enabled for this backend.
          backend = "kitty",
          processor = "magick_cli",
          debug = {
            enabled = true,
            level = "debug",
            format = "detailed",
            file_path = "/tmp/image.nvim.log",
          },
          integrations = {
            markdown = { enabled = true },
            neorg = { enabled = true },
            typst = { enabled = true },
            html = { enabled = true },
            css = { enabled = true },
          },
          max_width = nil,
          max_height = nil,
          max_width_window_percentage = 100,
          max_height_window_percentage = 100,
          -- Oil's split preview is incorrectly treated as an overlapping
          -- window by image.nvim, which prevents the Kitty render command.
          window_overlap_clear_enabled = false,
          window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
          -- Prevent Kitty images from remaining visible in inactive tmux
          -- windows when switching tabs.
          tmux_show_only_in_active_window = true,
        },
      },
    },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
}
