vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.textwidth = vim.g.markdown_text_width or 88
vim.opt_local.formatoptions:append "tcqnj"
vim.opt_local.formatoptions:remove "l"
vim.opt_local.formatlistpat =
  [[^\s*\d\+[\]:.)}\t ]\s*\|^\s*[-*+]\s\+\|^\s*>\s\+\|^\s*[-*+]\s\+\[[ xX]\]\s\+]]
vim.opt_local.joinspaces = false

local reader_group = vim.api.nvim_create_augroup("markdown_reader_mode", { clear = false })

local function set_window_options(options)
  for option, value in pairs(options) do
    vim.wo[option] = value
  end
end

local function set_global_options(options)
  for option, value in pairs(options) do
    vim.o[option] = value
  end
end

local function save_state()
  vim.w.markdown_reader_window_state = {
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    signcolumn = vim.wo.signcolumn,
    statuscolumn = vim.wo.statuscolumn,
    cursorline = vim.wo.cursorline,
    foldcolumn = vim.wo.foldcolumn,
    spell = vim.wo.spell,
    wrap = vim.wo.wrap,
    linebreak = vim.wo.linebreak,
    breakindent = vim.wo.breakindent,
    showbreak = vim.wo.showbreak,
    conceallevel = vim.wo.conceallevel,
    concealcursor = vim.wo.concealcursor,
    list = vim.wo.list,
    colorcolumn = vim.wo.colorcolumn,
    scrolloff = vim.wo.scrolloff,
    sidescrolloff = vim.wo.sidescrolloff,
  }

  vim.g.markdown_reader_global_state = vim.g.markdown_reader_global_state or {
    laststatus = vim.o.laststatus,
    showtabline = vim.o.showtabline,
    ruler = vim.o.ruler,
    showmode = vim.o.showmode,
  }
end

local function enable_reader()
  if vim.w.markdown_reader_enabled then return end

  save_state()
  vim.w.markdown_reader_enabled = true

  set_window_options {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    statuscolumn = "",
    cursorline = false,
    foldcolumn = "0",
    spell = true,
    wrap = true,
    linebreak = true,
    breakindent = true,
    showbreak = "",
    conceallevel = 2,
    concealcursor = "nc",
    list = false,
    colorcolumn = "",
    scrolloff = 8,
    sidescrolloff = 12,
  }

  set_global_options {
    laststatus = 0,
    showtabline = 0,
    ruler = false,
    showmode = false,
  }
end

local function disable_reader()
  if not vim.w.markdown_reader_enabled then return end

  local window_state = vim.w.markdown_reader_window_state
  if window_state then set_window_options(window_state) end

  local global_state = vim.g.markdown_reader_global_state
  if global_state then
    set_global_options(global_state)
    vim.g.markdown_reader_global_state = nil
  end

  vim.w.markdown_reader_enabled = false
end

local function toggle_reader()
  if vim.w.markdown_reader_enabled then
    disable_reader()
  else
    enable_reader()
  end
end

vim.api.nvim_buf_create_user_command(0, "MarkdownReaderOn", enable_reader, {
  desc = "Enable a distraction-free Markdown reader layout",
})

vim.api.nvim_buf_create_user_command(0, "MarkdownReaderOff", disable_reader, {
  desc = "Restore the normal Markdown editor layout",
})

vim.api.nvim_buf_create_user_command(0, "MarkdownReaderToggle", toggle_reader, {
  desc = "Toggle the Markdown reader layout",
})

vim.keymap.set("n", "<leader>mr", toggle_reader, {
  buffer = true,
  desc = "Toggle Markdown reader mode",
})

vim.api.nvim_create_autocmd("BufWinLeave", {
  group = reader_group,
  buffer = 0,
  callback = disable_reader,
})

if not vim.g.markdown_reader_tab_autocmd then
  vim.g.markdown_reader_tab_autocmd = true

  vim.api.nvim_create_autocmd({ "TabEnter", "TabNew" }, {
    group = reader_group,
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.w[win].markdown_reader_enabled then
          vim.api.nvim_win_call(win, disable_reader)
        end
      end
    end,
  })
end

local another_markdown_buffer_is_open = false
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if buf ~= vim.api.nvim_get_current_buf()
    and vim.api.nvim_buf_is_valid(buf)
    and vim.bo[buf].filetype == "markdown"
    and vim.bo[buf].buftype == ""
  then
    another_markdown_buffer_is_open = true
    break
  end
end

if vim.g.markdown_reader_auto ~= false
  and #vim.api.nvim_list_tabpages() == 1
  and not another_markdown_buffer_is_open
then
  enable_reader()
end

local undo_ftplugin = vim.b.undo_ftplugin
local undo_reader = table.concat({
  "silent! MarkdownReaderOff",
  "silent! delcommand -buffer MarkdownReaderOn",
  "silent! delcommand -buffer MarkdownReaderOff",
  "silent! delcommand -buffer MarkdownReaderToggle",
  "silent! nunmap <buffer> <leader>mr",
  "setlocal expandtab< shiftwidth< tabstop< softtabstop< textwidth< formatoptions< formatlistpat< joinspaces<",
}, " | ")

if undo_ftplugin then
  vim.b.undo_ftplugin = undo_ftplugin .. " | " .. undo_reader
else
  vim.b.undo_ftplugin = undo_reader
end
