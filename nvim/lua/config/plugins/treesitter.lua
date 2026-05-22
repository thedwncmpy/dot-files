return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      vim.treesitter.language.register("bash", "zsh")

      require("nvim-treesitter.configs").setup {
        ensure_installed = { "bash", "prisma", "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
        auto_install = false,
        highlight = {
          enable = true,
          disable = function(lang, buf)
            local ft = vim.bo[buf].filetype
            if ft == "zsh" then return true end
            if lang == "zsh" then return true end
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then return true end
          end,
          -- Shell files benefit from combining Tree-sitter with legacy regex
          -- highlights for a few edge-case constructs.
          additional_vim_regex_highlighting = { "bash", "zsh", "sh" },
        },
      }
    end,
  },
}
