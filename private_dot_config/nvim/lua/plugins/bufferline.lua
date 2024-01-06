return {
  {
    "akinsho/bufferline.nvim",
    enabled = false,
    opts = {
      options = {
        always_show_bufferline = true,
        separator_style = "slant",
        mode = "tabs",
        numbers = "ordinal",
        tab_size = 8,
        name_formatter = function()
          return ""
        end,
        show_duplicate_prefix = false,
        show_buffer_icons = false,
        show_close_icon = false,
      },
    },
  },
}
