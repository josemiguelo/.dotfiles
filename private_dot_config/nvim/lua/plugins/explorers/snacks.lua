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
      picker = {
        sources = {
          grep = custom_vertical_layout,
          explorer = custom_explorer_layout,
          files = custom_vertical_layout,
        },
      },
    },
  },
}
