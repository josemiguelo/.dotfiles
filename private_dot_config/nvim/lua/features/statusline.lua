return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_a = { { "mode", color = { gui = "bold" } } }
    opts.sections.lualine_b = { { "branch", color = { gui = "bold" } } }

    table.insert(opts.sections.lualine_x, 1, "filetype")

    opts.sections.lualine_y = {
      { "progress", color = { gui = "bold" }, separator = " ", padding = { left = 1, right = 0 } },
      { "location", color = { gui = "bold" }, padding = { left = 0, right = 1 } },
    }
    opts.sections.lualine_z = {}
  end,
}
