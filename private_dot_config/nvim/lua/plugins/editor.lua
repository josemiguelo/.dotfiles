return {
  {
    "folke/todo-comments.nvim",
    opts = {
      search = {
        pattern = [[\b(KEYWORDS):]], -- ripgrep regex
        -- pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
      },
    },
  },

  {
    "NvChad/nvim-colorizer.lua",
    config = true,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    config = function(opts)
      vim.opt.list = true
      vim.opt.listchars:append("space:⋅")
      vim.opt.listchars:append("eol:↴")

      require("ibl").setup(opts.opts)
    end,
  },

  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerToggle",
      "OverseerRun",
    },
    keys = {
      { "<leader>rt", "<Cmd>:OverseerToggle<CR>", desc = "Toggle Overseer" },
      { "<leader>rr", "<Cmd>:OverseerRun<CR>", desc = "Toggle Overseer" },
    },
    opts = {
      templates = {
        "builtin",
      },
      task_list = {
        bindings = {
          ["?"] = "ShowHelp",
          ["g?"] = "ShowHelp",
          ["<CR>"] = "RunAction",
          ["<C-e>"] = "Edit",
          ["o"] = "Open",
          ["<C-v>"] = "OpenVsplit",
          ["<C-s>"] = "OpenSplit",
          ["<C-f>"] = "OpenFloat",
          ["<C-q>"] = "OpenQuickFix",
          ["p"] = "TogglePreview",
          ["<C-l>"] = "IncreaseDetail",
          ["<C-h>"] = "DecreaseDetail",
          ["L"] = false,
          ["H"] = false,
          ["["] = "DecreaseAllDetail",
          ["]"] = "IncreaseAllDetail",
          ["{"] = "PrevTask",
          ["}"] = "NextTask",
          ["<C-k>"] = "ScrollOutputUp",
          ["<C-j>"] = "ScrollOutputDown",
        },
      },
    },
  },
}
