-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "config.plugins" },
    { import = "config.plugins.lsp" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- automatically check for plugin updates
  -- checker = { enabled = true },
})

--NVIM OPTIONS
vim.opt.expandtab = true   -- Use spaces instead of tabs
vim.opt.shiftwidth = 2    -- Size of an indent
vim.opt.tabstop = 2       -- Number of spaces tabs count for
vim.opt.softtabstop = 2   -- Number of spaces tabs count for while editing
vim.opt.clipboard = "unnamedplus"

if vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
-- 1. Enable wrapping
vim.opt.wrap = true
-- 2. THIS IS THE BIG ONE: It keeps the wrapped lines
-- aligned with the indentation of the starting line.
vim.opt.breakindent = true
-- 3. Prevents words from being split in the middle.
-- It will wait for a space/punctuation to wrap.
vim.opt.linebreak = true
vim.opt.autoread = true

-- FOLDING
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
