return {
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
        ["<C-l>"] = false,
        ["<C-h>"] = false,
        ["L"] = false,
        ["H"] = false,
        ["["] = "DecreaseAllDetail",
        ["]"] = "IncreaseAllDetail",
        ["{"] = "PrevTask",
        ["}"] = "NextTask",
        ["<C-k>"] = false,
        ["<C-j>"] = false,
      },
    },
  },
}
