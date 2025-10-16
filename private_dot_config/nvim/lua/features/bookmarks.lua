return {
  {
    "otavioschwanck/arrow.nvim",
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
    },
    opts = {
      show_icons = true,
      leader_key = "<leader>;", -- Recommended to be a single key
      buffer_leader_key = "m", -- Per Buffer Mappings
      index_keys = "jkl,gyuiopbnmafwrt", -- keys mapped to bookmark index
      separate_by_branch = true, -- Bookmarks will be separated by git branch
      mappings = {
        edit = "e",
        delete_mode = "d",
        clear_all_items = "C",
        toggle = "s", -- used as save if separate_save_and_remove is true
        open_vertical = "v",
        open_horizontal = "h",
        quit = "q",
        remove = "x", -- only used if separate_save_and_remove is true
        next_item = "]",
        prev_item = "[",
      },
      separate_save_and_remove = true, -- if true, will remove the toggle and create the save/remove keymaps.
      per_buffer_config = {
        lines = 10, -- Number of lines showed on preview.
      },
    },
  },
}
