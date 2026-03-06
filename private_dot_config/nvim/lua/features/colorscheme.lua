local hl = vim.api.nvim_set_hl

local reload_plugins = function()
  require("features.winbar")[1].config()
  require("features.tabbar")[2].config()
  require("features.blink_cursor")[1].config()
end

local apply_shared_highlights = function(c)
  hl(0, "LineNrAbove", { fg = c.blue })
  hl(0, "LineNrBelow", { fg = c.blue })
  hl(0, "SnacksPicker", { bg = "NONE" })
  hl(0, "SnacksPickerBorder", { bg = "NONE" })
  hl(0, "Normal", { bg = "NONE" })
  hl(0, "NormalFloat", { bg = "NONE" })
  hl(0, "SnacksTerminal", { bg = "NONE" })
  hl(0, "CursorLine", { bg = c.cursorline })
  hl(0, "CursorColumn", { bg = c.cursorline })
  hl(0, "diffAdded", { fg = c.green, bold = true })
  hl(0, "diffRemoved", { fg = c.red, bold = true })
  hl(0, "DiffText", { bg = c.cyan, bold = true, fg = "#000000" })
  hl(0, "GitSignsAdd", { fg = c.green })
  hl(0, "GitSignsChange", { fg = c.yellow })
  hl(0, "GitSignsDelete", { fg = c.red })
end

local apply_dark_highlights = function()
  local c = require("onedarkpro.helpers").get_colors()
  apply_shared_highlights(c)
  hl(0, "CursorLineNr", { fg = c.purple })
  hl(0, "WinSeparator", { fg = c.blue })
  hl(0, "FlashLabel", { bg = c.blue, bold = true, fg = c.cursorline })
end

local apply_light_highlights = function()
  local c = require("onedarkpro.helpers").get_colors()
  apply_shared_highlights(c)
  hl(0, "Comment", { fg = "#7380ba", italic = true })
  hl(0, "CursorLineNr", { fg = c.cyan })
  hl(0, "FlashLabel", { bg = "#ff007c", bold = true, fg = c.cursorline })
  local lighten = require("onedarkpro.helpers").lighten
  hl(0, "GitSignsStagedAdd", { fg = lighten("green", 35) })
  hl(0, "GitSignsStagedChange", { fg = lighten("yellow", 35) })
  hl(0, "GitSignsStagedDelete", { fg = lighten("red", 35) })
  local darken = require("onedarkpro.helpers").darken
  hl(0, "DiagnosticVirtualTextError", { fg = darken("red", 15), italic = true })
  hl(0, "DiagnosticVirtualTextWarn", { fg = darken("yellow", 15), italic = true })
  hl(0, "DiagnosticVirtualTextHint", { fg = darken("cyan", 15), italic = true })
  hl(0, "DiagnosticVirtualTextInfo", { fg = darken("blue", 15), italic = true })
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
