return {
  "nvim-telescope/telescope.nvim",
  -- master branch often has better support for Neovim Nightly (0.11)
  -- branch = "0.1.x",
  dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
  config = function()
    if not vim.g._lsp_make_position_params_patched then
      local original_make_position_params = vim.lsp.util.make_position_params
      vim.lsp.util.make_position_params = function(window, position_encoding)
        if position_encoding == nil then
          local ok, bufnr = pcall(function()
            if window then
              return vim.api.nvim_win_get_buf(window)
            end
            return vim.api.nvim_get_current_buf()
          end)
          if ok then
            local clients = vim.lsp.get_clients { bufnr = bufnr }
            if clients[1] then
              position_encoding = clients[1].offset_encoding or clients[1].position_encoding
            end
          end
        end
        return original_make_position_params(window, position_encoding)
      end
      vim.g._lsp_make_position_params_patched = true
    end

    local tele = require "telescope"
    local actions = require "telescope.actions"
    tele.setup {
      defaults = {
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
          },
          n = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
          },
        },
        layout_strategy = "vertical",
        layout_config = {
          vertical = {
            mirror = true,
            prompt_position = "top",
            preview_cutoff = 0,
          },
        },
        sorting_strategy = "ascending",
      },
      pickers = {
        find_files = {},
        live_grep = {},
        buffers = {},
        help_tags = {},
      },
      extensions = {
        fzf = {},
      },
    }

    tele.load_extension "fzf"

    require("config.telescope.multigrep").setup()
    local builtin = require "telescope.builtin"
    local function lsp_position_encoding(bufnr)
      local clients = vim.lsp.get_clients { bufnr = bufnr }
      if clients[1] then
        return clients[1].offset_encoding or clients[1].position_encoding
      end
      return "utf-16"
    end
    -- Narrow the symbol picker to callable members for quick code navigation.
    local function list_document_functions()
      local bufnr = vim.api.nvim_get_current_buf()
      builtin.lsp_document_symbols {
        bufnr = bufnr,
        position_encoding = lsp_position_encoding(bufnr),
        symbols = { "Function", "Method", "function", "method" },
      }
    end
    vim.keymap.set("n", "<leader>fd", list_document_functions, { desc = "Telescope document functions" })
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
    vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Telescope document symbols" })
    -- vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "LSP References" })
  end,
}
