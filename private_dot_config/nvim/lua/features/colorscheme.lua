local reload_plugins = function()
  require("features.winbar")[1].config()
  require("features.tabbar")[2].config()
  require("features.blink_cursor")[1].config()
end

local tokyonight_highlights = function(hl, colors)
  hl.Comment = { fg = "#7380ba" }

  -- cursor colors
  hl.CursorLineNr = { fg = colors.cyan }

  -- relative numbers
  hl.LineNrAbove = { fg = colors.blue1 }
  hl.LineNrBelow = { fg = colors.blue1 }

  -- snacks plugins
  hl.SnacksPicker = { bg = "none", nocombine = true }
  hl.SnacksPickerBorder = { bg = "none", nocombine = true }
  hl.Normal = { bg = "none", nocombine = true }
  hl.NormalFloat = { bg = "none", nocombine = true }
  hl.SnacksTerminal = { bg = "none", nocombine = true }

  -- flash
  hl.FlashLabel = { bg = "#ff007c", bold = true, fg = "#ffffff" }

  -- git
  hl.DiffText = { bg = "#ffffff" }
end

local onedark_highlights = {
  --
  CursorColumn = { bg = "${cursorline}" },
  CursorLineNr = { fg = "${purple}" },

  -- relative numbers
  LineNrAbove = { fg = "${blue}" },
  LineNrBelow = { fg = "${blue}" },

  WinSeparator = { fg = "${blue}" },

  -- snacks plugins
  SnacksPicker = { bg = "NONE" },
  SnacksPickerBorder = { bg = "NONE" },
  Normal = { bg = "NONE" },
  NormalFloat = { bg = "NONE" },
  SnacksTerminal = { bg = "NONE" },

  -- flash
  FlashLabel = { bg = "${blue}", bold = true, fg = "${cursorline}" },

  -- git
  DiffText = { bg = "${cyan}", bold = true, fg = "#000000" },
}

return {

  -- light theme
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      style = "day",
      lualine_bold = true,
      dim_inactive = true,
      on_colors = function(colors)
        colors.border = colors.blue6
      end,
      on_highlights = tokyonight_highlights,
    },
  },

  -- dark theme
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
      highlights = onedark_highlights,
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
        reload_plugins()
      end,
      set_light_mode = function()
        vim.notify("Enabling light mode 🌞")
        vim.api.nvim_set_option_value("background", "light", {})
        vim.cmd("colorscheme tokyonight-day")
        reload_plugins()
      end,
    },
  },

  { "catppuccin/nvim", cond = false },
}
