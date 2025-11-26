local custom_vertical_layout = {
  layout = {
    layout = {
      backdrop = false,
      width = 0.9,
      min_width = 80,
      height = 0.9,
      min_height = 20,
      box = "vertical",
      border = "rounded",
      title = "{title} {live} {flags}",
      title_pos = "center",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
      { win = "preview", title = "{preview}", height = 0.8, border = "top" },
    },
  },
}

local custom_explorer_layout = {
  layout = {
    layout = {
      width = 50,
      min_width = 50,
      position = "left",
      box = "vertical",
      {
        win = "input",
        height = 1,
        border = "none",
        title = "{title} {live} {flags}",
        title_pos = "center",
      },
      { win = "list", border = "none" },
    },
  },
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {},
      explorer = {},
    },
    -- stylua: ignore
    keys = {
      { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },

      { "<leader>fR", LazyVim.pick("oldfiles"), desc = "Recent" },
      { "<leader>fr", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "Recent (cwd)" },

      { "<leader>sG", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
      { "<leader>sg", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },

      { "<leader><space>", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        formatters = {
          file = { truncate = 999 },
        },
        sources = {
          smart = custom_vertical_layout,
          grep = custom_vertical_layout,
          explorer = custom_explorer_layout,
          files = custom_vertical_layout,
          buffers = custom_vertical_layout,
          notifications = custom_vertical_layout,
          oldfiles = custom_vertical_layout,
          recent = custom_vertical_layout,
          help = custom_vertical_layout,
          lsp_references = custom_vertical_layout,
          lsp_symbols = custom_vertical_layout,
        },
      },
    },
  },
}
