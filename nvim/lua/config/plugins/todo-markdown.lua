return {
  {
    dir = "~/dev/todo-markdown",
    name = "todo-markdown",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("telescope").load_extension("markdown_todos")
    end,
  },
}
