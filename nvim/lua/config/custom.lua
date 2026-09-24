-- Highlight yanked text and reload files changed by other processes.
-- Also define the :Ask command for opening Gemini in a floating terminal.
-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  -- Show Neovim's yank highlight for copied text.
  callback = function() vim.highlight.on_yank() end,
})

-- Pick up file changes made outside the current nvim instance.
-- `autoread` only enables reloading; `checktime` is what actually asks vim to detect changes.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose", "TermLeave" }, {
  desc = "Reload files changed outside of nvim",
  group = vim.api.nvim_create_augroup("checktime_on_focus", { clear = true }),
  callback = function()
    -- Avoid running :checktime while the command line is active.
    if vim.fn.mode() ~= "c" then vim.cmd "checktime" end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  desc = "Notify when a file reloads after an external change",
  group = vim.api.nvim_create_augroup("file_changed_shell_notify", { clear = true }),
  -- Tell the user when Neovim reloads a changed file from disk.
  callback = function() vim.notify("File reloaded from disk", vim.log.levels.INFO, { title = "nvim" }) end,
})

-- Run gemini in non-interactive mode with a prompt in a floating window
vim.api.nvim_create_user_command("Ask", function(opts)
  -- Open Gemini in a centered terminal window using the supplied prompt.
  local prompt = opts.args
  if prompt == "" then
    vim.notify("Prompt is required for :Ask", vim.log.levels.ERROR)
    return
  end

  -- Calculate floating window size and position
  local stats = vim.api.nvim_list_uis()[1]
  local width = math.floor(stats.width * 0.8)
  local height = math.floor(stats.height * 0.8)
  local row = math.floor((stats.height - height) / 2)
  local col = math.floor((stats.width - width) / 2)

  -- Create buffer and window
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Run terminal command
  vim.fn.termopen("gemini -p " .. vim.fn.shellescape(prompt))

  -- Start in insert mode
  vim.cmd "startinsert"

  -- Optional: Close window on terminal exit if you prefer
  -- vim.api.nvim_create_autocmd("TermClose", {
  --   buffer = buf,
  --   callback = function()
  --     vim.api.nvim_win_close(win, true)
  --   end,
  -- })
end, {
  nargs = "*",
  desc = "Run gemini in non-interactive mode with a prompt in a floating window",
})
