-- Kotlin/Native cinterop .def files: settings, `---`, then C. No grammar
-- exists for them, and Neovim reads *.def as Microsoft module-definition
-- files; C highlights everything after `---`. Set here, not in an `init`:
-- lazy.nvim keeps one `init` per plugin, so a second one on nvim-treesitter
-- would replace shell.lua's.
vim.filetype.add({
  pattern = { [".*/nativeInterop/cinterop/.*%.def"] = "c" },
})

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "c" },
    },
  },
}
