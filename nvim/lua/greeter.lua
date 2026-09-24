-- Custom Nvim greeting page
-- Add this to your init.lua or in a separate file that you source

-- Return the lines displayed on the startup greeting screen.
local function custom_intro()
  local version = vim.version()
  local nvim_version = string.format("NVIM v%d.%d.%d", version.major, version.minor, version.patch)

  local lines = {
    "",
    nvim_version,
    "",
    "Nvim is open source and freely distributable",
    "https://neovim.io/#chat",
    "",
    "type  <leader>ff              browse files",
    "type  <leader>q               to quit",
    "type  <leader>h               for help",
    "type  :help<Enter>            for help",
    "",
    "type  :help news<Enter> to see changes in v0.11",
    "",
    "Help poor children in Uganda!",
    "type  :help iccf<Enter>       for information",
    "",
  }

  return lines
end

-- Set up autocommand to show custom intro in floating window
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Display the greeting only when Neovim starts without file arguments.
    -- Only show on startup with no files
    if vim.fn.argc() == 0 and vim.fn.line2byte("$") == -1 then
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
      vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
      vim.api.nvim_buf_set_option(buf, "swapfile", false)
      vim.api.nvim_buf_set_option(buf, "filetype", "intro")

      local lines = custom_intro()

      -- Find the longest line to calculate proper width
      local max_width = 0
      for _, line in ipairs(lines) do
        if #line > max_width then
          max_width = #line
        end
      end

      -- Add padding
      max_width = max_width + 4

      -- Center each line within the buffer
      local centered_lines = {}
      for _, line in ipairs(lines) do
        local padding = math.floor((max_width - #line) / 2)
        table.insert(centered_lines, string.rep(" ", padding) .. line)
      end

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, centered_lines)
      vim.api.nvim_buf_set_option(buf, "modifiable", false)

      -- Calculate window dimensions
      local width = max_width
      local height = #centered_lines
      local ui = vim.api.nvim_list_uis()[1]
      local win_width = ui.width
      local win_height = ui.height

      -- Center the floating window
      local row = math.floor((win_height - height) / 2)
      local col = math.floor((win_width - width) / 2)

      -- Create floating window
      local opts = {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
      }

      local win = vim.api.nvim_open_win(buf, true, opts)

      -- Make window non-modifiable
      vim.api.nvim_win_set_option(win, "cursorline", false)
      vim.api.nvim_win_set_option(win, "number", false)
      vim.api.nvim_win_set_option(win, "relativenumber", false)
      vim.api.nvim_win_set_option(win, "winblend", 0)

      -- Close floating window on any key press or buffer change
      vim.keymap.set("n", "<Esc>", function()
        -- Close the greeting when Escape is pressed.
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end, { buffer = buf, nowait = true })

      vim.keymap.set("n", "<CR>", function()
        -- Close the greeting when Enter is pressed.
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end, { buffer = buf, nowait = true })

      -- Auto-close intro when starting to edit or switching buffers
      vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "BufNew" }, {
        buffer = buf,
        callback = function()
          -- Close the greeting before switching to another editing context.
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end,
      })
    end
  end,
})

-- Example keybindings (add these if you don't have them already)
-- vim.g.mapleader = " "  -- Set leader to space if not already set
-- vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>', { desc = 'Browse files' })
-- vim.keymap.set('n', '<leader>c', ':q<CR>', { desc = 'Quit' })
-- vim.keymap.set('n', '<leader>h', ':help<CR>', { desc = 'Help' })
