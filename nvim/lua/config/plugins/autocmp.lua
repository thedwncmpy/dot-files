-- Configure completion sources, snippet expansion, and insert-mode navigation.
return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
  },
  config = function()
    -- Set up nvim-cmp and connect its snippet support to LuaSnip.
    local cmp = require "cmp"
    -- Use the nvim-cmp source supplied by the Homebrew todo-markdown package.
    cmp.register_source("markdown_todos", require "telescope._extensions.markdown_todos.cmp_source")

    local luasnip = require "luasnip"

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup {
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args) luasnip.lsp_expand(args.body) end,
      },
      mapping = cmp.mapping.preset.insert {
        ["<C-k>"] = cmp.mapping(function(fallback)
          -- Prefer the previous completion item, then the prior snippet stop.
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-j>"] = cmp.mapping(function(fallback)
          -- Prefer the next completion item, then the next snippet stop.
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.locally_jumpable(1) then
            luasnip.jump(1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<CR>"] = cmp.mapping.confirm { select = true },
      },
      formatting = {
        format = function(entry, item)
          -- Mark todo categories so they are distinguishable from buffer words.
          if entry.source.name == "markdown_todos" then item.menu = "[todos]" end
          return item
        end,
      },
      -- sources for autocompletion
      -- Prefer task category completions; use normal sources when no category matches.
      sources = cmp.config.sources(
        { { name = "markdown_todos" } },
        {
          { name = "nvim_lsp" },
          { name = "luasnip" }, -- snippets
          { name = "buffer" }, -- text within current buffer
          { name = "path" }, -- file system paths
        }
      ),
    }
  end,
}
