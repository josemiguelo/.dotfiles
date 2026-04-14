local reload_plugins = function()
  require("features.winbar")[1].config()
  require("features.tabbar")[2].config()
  require("features.blink_cursor")[1].config()
end

return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    opts = {
      colors = {
        onedark = {
          diag_error_sp = "require('onedarkpro.helpers').lighten('red', 9.3, 'onedark')",
          diag_warn_sp = "require('onedarkpro.helpers').lighten('yellow', 9, 'onedark')",
          diag_hint_sp = "require('onedarkpro.helpers').lighten('cyan', 10.8, 'onedark')",
          diag_info_sp = "require('onedarkpro.helpers').lighten('blue', 10.2, 'onedark')",
        },
        onelight = {
          staged_green = "require('onedarkpro.helpers').lighten('green', 35, 'onelight')",
          staged_yellow = "require('onedarkpro.helpers').lighten('yellow', 35, 'onelight')",
          staged_red = "require('onedarkpro.helpers').lighten('red', 35, 'onelight')",
          diag_error_sp = "require('onedarkpro.helpers').lighten('red', 15, 'onelight')",
          diag_warn_sp = "require('onedarkpro.helpers').lighten('yellow', 15, 'onelight')",
          diag_hint_sp = "require('onedarkpro.helpers').darken('cyan', 15, 'onelight')",
          diag_info_sp = "require('onedarkpro.helpers').lighten('blue', 26, 'onelight')",
          diag_error_fg = "require('onedarkpro.helpers').lighten('red', 15, 'onelight')",
          diag_warn_fg = "require('onedarkpro.helpers').lighten('yellow', 15, 'onelight')",
          diag_hint_fg = "require('onedarkpro.helpers').darken('cyan', 10, 'onelight')",
          diag_info_fg = "require('onedarkpro.helpers').lighten('blue', 26, 'onelight')",
          cursorline = "require('onedarkpro.helpers').darken('bg', 13, 'onelight')",
        },
      },
      highlights = {
        LineNrAbove = { fg = "${blue}", extend = true },
        LineNrBelow = { fg = "${blue}", extend = true },
        SnacksPicker = { bg = "NONE", extend = true },
        SnacksPickerBorder = { bg = "NONE", extend = true },
        SnacksTerminal = { bg = "NONE", extend = true },
        CursorLine = { bg = "${cursorline}", extend = true },
        CursorColumn = { bg = "${cursorline}", extend = true },
        Added = { fg = "${green}", extend = true },
        Removed = { fg = "${red}", extend = true },
        Changed = { fg = "${yellow}", bold = true, extend = true },
        diffAdded = { link = "Added" },
        diffRemoved = { link = "Removed" },
        diffSubname = { fg = "${blue}", bold = true, extend = true, underline = true, italic = true },
        diffIndexLine = { fg = "${blue}", bold = true, extend = true, underline = true, italic = true },
        diffFile = { fg = "${blue}", bold = true, extend = true, underline = true, italic = true },
        diffLine = { fg = "${blue}", bold = true, extend = true, underline = true, italic = true },
        diffOldFile = { fg = "${blue}", bold = true, extend = true, underline = true, italic = true },
        diffNewFile = { fg = "${blue}", bold = true, extend = true, underline = true, italic = true },
        fugitiveUnstagedSection = { fg = "${purple}", bold = true, extend = true, underline = true, italic = true },
        fugitiveStagedSection = { fg = "${purple}", bold = true, extend = true, underline = true, italic = true },
        gitdiff = { fg = "${blue}", bold = true, extend = true, underline = true, italic = true },
        DiffText = { bg = "${cyan}", bold = true, fg = "#000000", extend = true },
        GitSignsAdd = { fg = "${green}", extend = true },
        GitSignsChange = { fg = "${yellow}", extend = true },
        GitSignsDelete = { fg = "${red}", extend = true },
        DapStoppedLine = { link = "Visual" },
        FugitiveDeltaText = { link = "DiffText" },
        DiagnosticVirtualTextError = {
          undercurl = true,
          italic = true,
          bold = true,
          fg = { onelight = "${diag_error_fg}" },
          sp = "${diag_error_sp}",
          extend = true,
        },
        DiagnosticVirtualTextWarn = {
          undercurl = true,
          italic = true,
          bold = true,
          fg = { onelight = "${diag_warn_fg}" },
          sp = "${diag_warn_sp}",
          extend = true,
        },
        DiagnosticVirtualTextHint = {
          undercurl = true,
          italic = true,
          bold = true,
          fg = { onelight = "${diag_hint_fg}" },
          sp = "${diag_hint_sp}",
          extend = true,
        },
        DiagnosticVirtualTextInfo = {
          undercurl = true,
          italic = true,
          bold = true,
          fg = { onelight = "${diag_info_fg}" },
          sp = "${diag_info_sp}",
          extend = true,
        },
        CursorLineNr = {
          fg = { onedark = "${purple}", onelight = "${cyan}" },
          extend = true,
        },
        WinSeparator = {
          fg = { onedark = "${blue}" },
          extend = true,
        },
        FlashLabel = {
          bg = { onedark = "${blue}", onelight = "#ff007c" },
          bold = true,
          fg = "${cursorline}",
          extend = true,
        },
        Comment = {
          fg = { onelight = "#7380ba" },
          italic = true,
          extend = true,
        },
        GitSignsStagedAdd = { fg = { onelight = "${staged_green}" }, extend = true },
        GitSignsStagedChange = { fg = { onelight = "${staged_yellow}" }, extend = true },
        GitSignsStagedDelete = { fg = { onelight = "${staged_red}" }, extend = true },
      },
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

  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      set_dark_mode = function()
        vim.notify("Enabling dark mode 🌚")
        vim.api.nvim_set_option_value("background", "dark", {})
        vim.cmd("colorscheme onedark")
        reload_plugins()
      end,
      set_light_mode = function()
        vim.notify("Enabling light mode 🌞")
        vim.api.nvim_set_option_value("background", "light", {})
        vim.cmd("colorscheme onelight")
        reload_plugins()
      end,
    },
  },

  { "catppuccin/nvim", cond = false },
}
