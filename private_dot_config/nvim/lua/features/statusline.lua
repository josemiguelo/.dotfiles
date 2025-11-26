local function enhance_section(opts, section, feature)
  opts.sections["lualine_" .. section] = {
    { feature, color = { gui = "bold,italic" } },
  }
end

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    enhance_section(opts, "a", "mode")
    enhance_section(opts, "b", "branch")

    table.insert(opts.sections.lualine_x, 1, "filetype")
    opts.sections.lualine_z = {}
  end,
}
