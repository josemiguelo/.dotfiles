return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = true,
    init = function() end,
    keys = {
      { "<leader>fe", vim.NIL },
      { "<leader>fE", vim.NIL },
      { "<leader>e", vim.NIL },
      { "<leader>E", vim.NIL },
      {
        "<leader>fne",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      {
        "<leader>fnE",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = require("lazyvim.util").get_root() })
        end,
        desc = "Explorer NeoTree (root dir)",
      },
    },
  },
}
