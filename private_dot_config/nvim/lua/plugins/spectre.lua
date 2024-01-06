return { -- search/replace in multiple files
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    config = function()
      local keys = {
        ["<leader>sr"] = { name = "+Spectre" },
      }
      require("which-key").register(keys)
    end,
    keys = {
      { "<leader>sr", vim.NIL },
      {
        "<leader>srR",
        '<cmd>lua require("spectre").open()<CR>',
        desc = "Open",
      },
      {
        "<leader>srw",
        '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
        desc = "Search current word",
      },
      {
        "<leader>srw",
        '<esc><cmd>lua require("spectre").open_visual()<CR>',
        desc = "Search selection",
        mode = "v",
      },
      {
        "<leader>srr",
        '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
        desc = "Search current word on current file",
      },
    },
  },
}
