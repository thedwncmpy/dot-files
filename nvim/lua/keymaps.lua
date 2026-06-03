-- ========================================================================== --
--                                  KEYMAPS                                   --
-- ========================================================================== --

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

-- Navigate: Use Ctrl + Option + H and L to cycle between open buffers
vim.keymap.set("n", "<M-C-h>", ":bnext<CR>", { noremap = true, silent = true, desc = "Prev buffer" })
vim.keymap.set("n", "<M-C-l>", ":bprev<CR>", { noremap = true, silent = true, desc = "Next buffer" })

-- WINDOWS & QUITTING
vim.keymap.set("n", "<leader>q", ":qa<CR>", { desc = "Quit all" })

-- MOVING TEXT (Visual Mode)
vim.keymap.set("x", "<C-j>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move block down" })
vim.keymap.set("x", "<C-k>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move block up" })

-- SNIPPET JUMPING (Select Mode)
vim.keymap.set(
  "s",
  "<C-j>",
  function() require("luasnip").jump(1) end,
  { silent = true, desc = "Jump forward (Luasnip)" }
)
vim.keymap.set(
  "s",
  "<C-k>",
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
