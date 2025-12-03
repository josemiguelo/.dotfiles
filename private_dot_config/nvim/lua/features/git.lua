local get_window_by_ft = require("util.windows").get_window_by_ft

local function fugitive_toggle_window()
  local fugitive_win = get_window_by_ft("fugitive")
  if fugitive_win then
    vim.api.nvim_win_close(fugitive_win, true)
  else
    vim.cmd("G")
  end
end

return {
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gvdiffsplit",
      "Gedit",
      "Gsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "Glgrep",
      "Gmove",
      "Gdelete",
      "GRemove",
      "Gbrowse",
    },
    keys = {
      {
        "<leader>gg",
        function()
          if vim.v.count > 0 then
            vim.cmd("G")
          else
            fugitive_toggle_window()
          end
        end,
        desc = "GitUi (Root Dir)",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "diff",
        "git_config",
        "git_rebase",
        "gitcommit",
        "gitattributes",
        "gitignore",
      },
    },
  },

  {
    "rbong/vim-flog",
    event = "VeryLazy",
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = { "tpope/vim-fugitive" },
  },
  {
    "tpope/vim-rhubarb",
    event = "VeryLazy",
  },
  {
    "shumphrey/fugitive-gitlab.vim",
    event = "VeryLazy",
  },
  {
    "farhanmustar/fugitive-delta.nvim",
    event = "VeryLazy",
  },
}
