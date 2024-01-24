return {
  {
    "folke/persistence.nvim",
    enabled = false,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "olimorris/persisted.nvim",
        lazy = false,
        opts = {
          use_git_branch = true,
          follow_cwd = false,
          autosave = true,
          allowed_dirs = {
            "~/.config/nvim",
          },
        },
        config = function(_, opts)
          local wk = require("which-key")
          local keys = { mode = { "n" }, ["<leader>z"] = { name = "+Sessions" } }
          wk.register(keys)

          require("persisted").setup(opts)
          require("telescope").load_extension("persisted")
        end,
        keys = {
          { "<leader>zz", "<Cmd>Telescope persisted<CR>", desc = "List session" },
          { "<leader>zs", "<Cmd>SessionSave<CR>", desc = "Save session" },
        },
      },
    },
  },
}
