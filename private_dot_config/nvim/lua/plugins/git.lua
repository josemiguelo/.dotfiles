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
    -- keys = {
    --   { "<leader>gc", "<cmd>G commit<cr>", desc = "commit" },
    --   { "<leader>gg", "<cmd>0tab G<cr>", desc = "status" },
    --   { "<leader>gG", "<cmd>Gclog!<cr>", desc = "history" },
    --   { "<leader>gb", "<cmd>G blame<cr>", desc = "blame" },
    -- },
  },
  {
    "rbong/vim-flog",
    event = "VeryLazy",
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = { "tpope/vim-fugitive" },
  },
}
