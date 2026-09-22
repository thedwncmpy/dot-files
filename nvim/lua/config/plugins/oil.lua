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
        config = function(_, opts)
          local image = require("image")
          image.setup(opts)

          local pane_id = vim.env.TMUX_PANE
          if not pane_id then return end

          local picker_open = false
          local restore_images = false
          vim.fn.timer_start(200, function()
            if not picker_open and #image.get_images() == 0 then return end

            local result = vim.fn.system({ "tmux", "display-message", "-p", "-t", pane_id, "#{pane_mode}|#{client_tty}" })
            if vim.v.shell_error ~= 0 then return end
            local mode, client_tty = result:match("^([^|]*)|([^\n]*)")
            if not mode then return end

            local in_picker = mode == "tree-mode"
            if in_picker == picker_open then return end

            picker_open = in_picker
            if in_picker then
              restore_images = image.is_enabled()
              if not restore_images then return end

              -- tmux can hold pane output in choose-tree; send Kitty deletes to the client TTY.
              if client_tty ~= "" then
                local tty = io.open(client_tty, "w")
                if tty then
                  for _, current_image in ipairs(image.get_images()) do
                    if current_image.is_rendered then
                      tty:write(("\27_Ga=d,d=i,i=%d,q=2\27\\"):format(current_image.internal_id))
                    end
                  end
                  tty:close()
                end
              end
              image.disable()
            elseif restore_images then
              image.enable()
              restore_images = false
            end
          end, { ["repeat"] = -1 })
        end,
      },
    },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
}
