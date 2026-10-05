-- ========================================================================== --
--                                  KEYMAPS                                   --
-- ========================================================================== --
-- Define editor navigation, buffer, window, text movement, and diagnostic keys.

-- SOURCE / EXECUTE
vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>", { desc = "Source current file" })
vim.keymap.set("n", "<space>x", ":.lua<CR>", { desc = "Execute current line" })
vim.keymap.set("v", "<space>x", ":lua<CR>", { desc = "Execute selection" })

-- NAVIGATION (Word-wise h/l)
-- Note: h is now Back (b) and l is now Forward (w)
vim.keymap.set({ "n", "v", "o" }, "h", "b", { noremap = true, desc = "Move back word" })
vim.keymap.set({ "n", "v", "o" }, "l", "w", { noremap = true, desc = "Move forward word" })
vim.keymap.set({ "n", "v" }, "{", "{zz", { desc = "Jump back paragraph and center" })
vim.keymap.set({ "n", "v" }, "}", "}zz", { desc = "Jump forward paragraph and center" })

-- BUFFERS
vim.keymap.set("n", "<leader>c", ":bdelete<CR>", { noremap = true, silent = true, desc = "Close buffer" })
-- Reorder: Use Ctrl + [ and ] to physically move the buffer in the list
vim.keymap.set("n", "<C-[>", ":BufferLineMovePrev<CR>", { noremap = true, silent = true, desc = "Move buffer left" })
vim.keymap.set("n", "<C-]>", ":BufferLineMoveNext<CR>", { noremap = true, silent = true, desc = "Move buffer right" })

-- Navigate: Use Option + H and L to cycle between open buffers
vim.keymap.set("n", "<M-h>", ":bprev<CR>", { noremap = true, silent = true, desc = "Prev buffer" })
vim.keymap.set("n", "<M-l>", ":bnext<CR>", { noremap = true, silent = true, desc = "Next buffer" })

-- WINDOWS & QUITTING
vim.keymap.set("n", "<leader>q", ":qa<CR>", { desc = "Quit all" })

-- Keep one Codex terminal per tab so hiding the split preserves its session.
local codex_splits = {}
local function toggle_codex_split()
  local tab = vim.api.nvim_get_current_tabpage()
  local split = codex_splits[tab]
  if split and vim.api.nvim_win_is_valid(split.win) then
    vim.api.nvim_win_close(split.win, true)
    return
  end

  local running = split and vim.api.nvim_buf_is_valid(split.buf) and vim.fn.jobwait({ split.job }, 0)[1] == -1
  if not running and vim.fn.executable("codex") ~= 1 then
    vim.notify("codex executable not found", vim.log.levels.ERROR)
    return
  end

  vim.cmd "botright vsplit"
  local win = vim.api.nvim_get_current_win()
  if running then
    vim.api.nvim_win_set_buf(win, split.buf)
    split.win = win
  else
    if split and vim.api.nvim_buf_is_valid(split.buf) then vim.api.nvim_buf_delete(split.buf, { force = true }) end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "hide"
    vim.api.nvim_win_set_buf(win, buf)
    local job = vim.fn.termopen { "codex" }
    codex_splits[tab] = { buf = buf, win = win, job = job }
  end
  vim.cmd "startinsert"
end
vim.keymap.set("n", "<leader>ai", toggle_codex_split, { desc = "Toggle Codex split" })

-- MOVING TEXT (Visual Mode)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move block down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move block up" })
vim.keymap.set("v", "<leader>j", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move block down" })
vim.keymap.set("v", "<leader>k", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move block up" })

-- SNIPPET JUMPING (Select Mode)
vim.keymap.set(
  "s",
  "<C-j>",
  -- Jump to the next LuaSnip placeholder.
  function() require("luasnip").jump(1) end,
  { silent = true, desc = "Jump forward (Luasnip)" }
)
vim.keymap.set(
  "s",
  "<C-k>",
  -- Jump to the previous LuaSnip placeholder.
  function() require("luasnip").jump(-1) end,
  { silent = true, desc = "Jump backward (Luasnip)" }
)

-- QUICKFIX & DIAGNOSTICS
vim.keymap.set("n", "<M-]>", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
vim.keymap.set("n", "<M-[>", "<cmd>cprev<CR>", { desc = "Prev quickfix item" })
vim.keymap.set("n", "<M-o>", "<cmd>copen<CR>", { desc = "Open quickfix window" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open diagnostic float" })
-- Populate quickfix with diagnostics from all listed buffers.
vim.keymap.set(
  "n",
  "<leader>d",
  -- Populate quickfix with diagnostics from all listed buffers.
  function() vim.diagnostic.setqflist() end,
  { desc = "Set quickfix list with diagnostics" }
)

-- OIL.NVIM
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
-- Definition Lookup
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP Definition" })
-- ========================================================================== --
--                                 AUTOCMDS                                   --
-- ========================================================================== --

-- HELP WINDOW (Always open on the far right)
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("HelpVerticalSplit", { clear = true }),
  pattern = "help",
  callback = function() vim.cmd "wincmd L" end,
})
