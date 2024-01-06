local function cmd(command)
  return table.concat({ "<Cmd>", command, "<CR>" })
end

return {
  {
    "anuvyklack/windows.nvim",
    lazy = false,
    dependencies = {
      { "anuvyklack/middleclass" },
      { "anuvyklack/animation.nvim" },
    },
    keys = {
      { "<leader>wmm", cmd("WindowsMaximize"), desc = "Maximize Window" },
      { "<leader>wmv", cmd("WindowsMaximizeVertically"), desc = "Maximize Window Vertically" },
      { "<leader>wmh", cmd("WindowsMaximizeHorizontally"), desc = "Maximize Window Horizontally" },
      { "<leader>wme", cmd("WindowsEqualize"), desc = "Equalize Windows" },
      { "<leader>wmt", cmd("WindowsToggleAutowidth"), desc = "Toggle autowidth" },
    },
    config = function()
      vim.o.winwidth = 10
      vim.o.winminwidth = 10
      vim.o.equalalways = false

      require("windows").setup({
        autowidth = {
          enable = false,
        },
      })

      local keys = {
        ["<leader>wm"] = { name = "+maximize" },
      }
      require("which-key").register(keys)
    end,
  },
}
