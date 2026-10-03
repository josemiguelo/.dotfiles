return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      vim.filetype.add({
        extension = {
          tfvars = "terraform",
        },
      })
    end,
    opts = {
      ensure_installed = { "terraform" },
    },
  },
}
