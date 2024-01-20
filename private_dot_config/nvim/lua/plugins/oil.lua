return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  keys = { { "<leader>e", "<cmd>Oil --float<CR>", desc = "Oil file manager" } },
  opts = {
    columns = {
      "icon",
      { "mtime", highlight = "Comment", format = "%T %y-%m-%d" },
    },
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
    },
    float = {
      padding = 3,
      win_options = {
        winblend = 0,
      },
    },
  },
}