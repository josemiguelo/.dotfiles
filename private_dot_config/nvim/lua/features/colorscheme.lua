--- @param ns_id integer Namespace id for this highlight `nvim_create_namespace()`.
--- @param name string Highlight group name, e.g. "ErrorMsg"
--- @param overrides vim.api.keyset.highlight Highlight definition map, accepts the following keys:
local extend_hl = function(ns_id, name, overrides)
  local current_hl = vim.api.nvim_get_hl(0, { name = name })
  vim.api.nvim_set_hl(ns_id, name, vim.tbl_extend("force", current_hl, overrides or {}))
end

local diagnostic_types = { "Error", "Warn", "Info", "Hint" }

local reload_plugins = function()
  require("features.winbar")[1].config()
  require("features.tabbar")[2].config()
  require("features.blink_cursor")[1].config()
end

local apply_shared_highlights = function(c)
  extend_hl(0, "LineNrAbove", { fg = c.blue })
  extend_hl(0, "LineNrBelow", { fg = c.blue })
  extend_hl(0, "SnacksPicker", { bg = "NONE" })
  extend_hl(0, "SnacksPickerBorder", { bg = "NONE" })
  extend_hl(0, "Normal", { bg = "NONE" })
  extend_hl(0, "NormalFloat", { bg = "NONE" })
  extend_hl(0, "SnacksTerminal", { bg = "NONE" })
  extend_hl(0, "CursorLine", { bg = c.cursorline })
  extend_hl(0, "CursorColumn", { bg = c.cursorline })
  extend_hl(0, "diffAdded", { fg = c.green, bold = true })
  extend_hl(0, "diffRemoved", { fg = c.red, bold = true })
  extend_hl(0, "diffSubname", { fg = c.purple, bold = true })
  extend_hl(0, "diffIndexLine", { fg = c.purple, bold = true })
  extend_hl(0, "diffFile", { fg = c.blue, bold = true })
  extend_hl(0, "diffOldFile", { fg = c.blue, bold = true })
  extend_hl(0, "diffNewFile", { fg = c.blue, bold = true })
  extend_hl(0, "DiffText", { bg = c.cyan, bold = true, fg = "#000000" })
  extend_hl(0, "GitSignsAdd", { fg = c.green })
  extend_hl(0, "GitSignsChange", { fg = c.yellow })
  extend_hl(0, "GitSignsDelete", { fg = c.red })
  extend_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

  for _, type in ipairs(diagnostic_types) do
    extend_hl(0, "DiagnosticVirtualText" .. type, { undercurl = true, italic = true, bold = true })
  end
end

local apply_dark_highlights = function()
  local c = require("onedarkpro.helpers").get_colors()
  apply_shared_highlights(c)

  extend_hl(0, "CursorLineNr", { fg = c.purple })
  extend_hl(0, "WinSeparator", { fg = c.blue })
  extend_hl(0, "FlashLabel", { bg = c.blue, bold = true, fg = c.cursorline })
end

local apply_light_highlights = function()
  local c = require("onedarkpro.helpers").get_colors()
  apply_shared_highlights(c)

  local lighten = require("onedarkpro.helpers").lighten
  local darken = require("onedarkpro.helpers").darken

  extend_hl(0, "Comment", { fg = "#7380ba", italic = true })
  extend_hl(0, "CursorLineNr", { fg = c.cyan })
  extend_hl(0, "FlashLabel", { bg = "#ff007c", bold = true, fg = c.cursorline })
  extend_hl(0, "GitSignsStagedAdd", { fg = lighten("green", 35) })
  extend_hl(0, "GitSignsStagedChange", { fg = lighten("yellow", 35) })
  extend_hl(0, "GitSignsStagedDelete", { fg = lighten("red", 35) })
  extend_hl(0, "DiagnosticVirtualTextError", { fg = "red", sp = "red" })
  extend_hl(0, "DiagnosticVirtualTextWarn", { fg = "orange", sp = "orange" })
  extend_hl(0, "DiagnosticVirtualTextHint", { fg = darken("cyan", 10), sp = darken("cyan", 15) })
  extend_hl(0, "DiagnosticVirtualTextInfo", { fg = "blue", sp = "blue" })
end

return {

  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    opts = {
      options = {
        transparency = true,
        terminal_colors = true,
        lualine_transparency = true,
        highlight_inactive_windows = true,
      },
      styles = {
        types = "bold",
        methods = "bold",
        numbers = "NONE",
        strings = "NONE",
        comments = "italic",
        keywords = "bold,italic",
        constants = "bold",
        functions = "italic",
        operators = "NONE",
        variables = "NONE",
        parameters = "italic",
        conditionals = "bold,italic",
        virtual_text = "italic",
      },
    },
  },

  -- it enables the appropriate theme at startup AND in runtime when OS's theme has changed
  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      set_dark_mode = function()
        vim.notify("Enabling dark mode 🌚")
        vim.api.nvim_set_option_value("background", "dark", {})
        vim.cmd("colorscheme onedark")
        apply_dark_highlights()
        reload_plugins()
        vim.cmd([[ highlight link FugitiveDeltaText DiffText ]])
      end,
      set_light_mode = function()
        vim.notify("Enabling light mode 🌞")
        vim.api.nvim_set_option_value("background", "light", {})
        vim.cmd("colorscheme onelight")
        apply_light_highlights()
        reload_plugins()
        vim.cmd([[ highlight link FugitiveDeltaText DiffText ]])
      end,
    },
  },

  { "catppuccin/nvim", cond = false },
}
