return {
  "declancm/maximize.nvim",
  -- config = true,
  opts = {
    default_keymaps = false,
  },
  keys = {
    { "<leader>Z", "<Cmd>lua require('maximize').toggle()<CR>", desc = "Toggle Maximize" },
  },
}
