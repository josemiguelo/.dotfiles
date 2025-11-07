return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_x, 1, "filetype")
    opts.sections.lualine_z = {}
  end,
}
