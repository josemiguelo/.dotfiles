return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "bash" },
    },
    init = function()
      -- use bash parser for zsh files
      vim.treesitter.language.register("bash", "zsh")

      vim.filetype.add({
        extension = {
          zsh = "sh",
          sh = "sh", -- force sh-files with zsh-shebang to still get sh as filetype
        },
        filename = {
          [".zshrc"] = "sh",
          [".zshenv"] = "sh",
        },
      })
    end,
  },
}
