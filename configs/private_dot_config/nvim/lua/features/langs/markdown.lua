LazyVim.on_very_lazy(function()
  vim.filetype.add({
    extension = { mdx = "markdown.mdx" },
  })
end)

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "markdown",
        "markdown_inline",
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- chezmoi.vim types a .md.tmpl source as markdown.chezmoitmpl, and the
    -- plugin attaches only to filetypes listed here, by exact name.
    opts = {
      file_types = { "markdown", "markdown.chezmoitmpl" },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
  },
}
