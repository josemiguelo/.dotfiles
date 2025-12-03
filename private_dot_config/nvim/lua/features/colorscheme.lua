return {

  -- light theme
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      style = "storm",
      lualine_bold = true,
      dim_inactive = true,
      on_colors = function(colors)
        colors.border = colors.blue6
      end,
      on_highlights = function(hl, colors)
        hl.CursorLineNr = { fg = colors.cyan }
        hl.LineNrAbove = { fg = colors.blue1 }
        hl.LineNrBelow = { fg = colors.blue1 }
        hl.Comment = { fg = "#7380ba" }

        hl.SnacksPicker = { bg = "none", nocombine = true }
        hl.SnacksPickerBorder = { bg = "none", nocombine = true }
        hl.Normal = { bg = "none", nocombine = true }
        hl.NormalFloat = { bg = "none", nocombine = true }
        hl.SnacksTerminal = { bg = "none", nocombine = true }

        hl.FlashLabel = { bg = "#ff007c", bold = true, fg = "#ffffff" }
        hl.DiffText = { bg = "#ffffff" }
      end,
    },
  },

  -- dark theme
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    opts = {
      highlights = {
        CursorLineNr = { fg = "${purple}" },
        LineNrAbove = { fg = "${blue}" },
        LineNrBelow = { fg = "${blue}" },
        CursorColumn = { bg = "${cursorline}" },
        WinSeparator = { fg = "${blue}" },
        SnacksPicker = { bg = "NONE" },
        SnacksPickerBorder = { bg = "NONE" },
        Normal = { bg = "NONE" },
        NormalFloat = { bg = "NONE" },
        SnacksTerminal = { bg = "NONE" },
        FlashLabel = { bg = "${blue}", bold = true, fg = "${cursorline}" },
        DiffText = { bg = "${cursorline}" },
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

  -- it enables the appropriate theme at startup AND in runtime when OS's theme has changed
  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      set_dark_mode = function()
        vim.notify("Enabling dark mode 🌚")
        vim.api.nvim_set_option_value("background", "dark", {})
        vim.cmd("colorscheme onedark")
        require("features.winbar")[1].config()
        require("features.tabbar")[2].config()
      end,
      set_light_mode = function()
        vim.notify("Enabling light mode 🌞")
        vim.api.nvim_set_option_value("background", "light", {})
        vim.cmd("colorscheme tokyonight-day")
        require("features.winbar")[1].config()
        require("features.tabbar")[2].config()
      end,
    },
  },

  { "catppuccin/nvim", cond = false },
}
