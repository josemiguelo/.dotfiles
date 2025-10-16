return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "python",
        "rst", -- python reST
        "requirements", -- pip requirements file
      },
    },
  },
}
