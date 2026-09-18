local reload_plugins = function()
  require("features.winbar")[1].config()
  require("features.tabbar")[2].config()
  require("features.blink_cursor")[1].config()
end

-- merge onto what the theme already set instead of replacing the whole group
local function extend(highlights, group, opts)
  highlights[group] = vim.tbl_extend("force", highlights[group] or {}, opts)
end

local function luminance(hex)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  return (0.299 * tonumber(r, 16) + 0.587 * tonumber(g, 16) + 0.114 * tonumber(b, 16)) / 255
end

-- palette lightness flips between the storm and day styles, so pick the
-- foreground from the background that actually resolved
local function contrast_fg(bg)
  return luminance(bg) > 0.5 and "#000000" or "#ffffff"
end

return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "storm",
      light_style = "day",
      transparent = true,
      terminal_colors = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_colors = function(colors)
        colors.border = colors.blue6
        -- storm's #565f89 contrasts 4.1:1 on bg; this clears 5.7:1 and stays
        -- below the #c0caf5 body text. Day is fine as-is.
        if luminance(colors.bg) < 0.5 then
          colors.comment = "#8b93c4"
        end
      end,
      on_highlights = function(hl, c)
        local light = luminance(c.bg) > 0.5
        local blend = require("tokyonight.util").blend
        local emphasis = { bold = true, underline = true, italic = true }

        for _, group in ipairs({
          "Normal",
          "NormalFloat",
          "SnacksPicker",
          "SnacksPickerBorder",
          "SnacksTerminal",
        }) do
          extend(hl, group, { bg = c.none, nocombine = true })
        end

        extend(hl, "LineNrAbove", { fg = c.blue1 })
        extend(hl, "LineNrBelow", { fg = c.blue1 })

        extend(hl, "CursorLine", { bg = c.bg_highlight })
        extend(hl, "CursorColumn", { bg = c.bg_highlight })
        extend(hl, "CursorLineNr", { fg = light and c.cyan or c.purple })

        extend(hl, "FlashLabel", { bg = c.magenta2, fg = contrast_fg(c.magenta2), bold = true })

        if light then
          extend(hl, "Comment", { fg = "#7380ba", italic = true })
        end

        extend(hl, "@variable", { fg = c.cyan })

        -- c.git holds the sign colors, c.diff the region tints
        extend(hl, "Added", { fg = c.git.add })
        extend(hl, "Removed", { fg = c.git.delete })
        extend(hl, "Changed", { fg = c.git.change, bold = true })

        -- c.git.add/delete are muted and get lost on the diff tints, so the diff
        -- body uses the saturated syntax colors instead
        extend(hl, "diffAdded", { fg = c.green })
        extend(hl, "diffRemoved", { fg = c.red })

        -- Tokyo Night already gives each diff header its own color, so carry over
        -- only the emphasis and let its palette supply the foreground
        for _, group in ipairs({
          "diffFile",
          "diffLine",
          "diffIndexLine",
          "diffOldFile",
          "diffNewFile",
        }) do
          extend(hl, group, emphasis)
        end

        -- these two it leaves undefined, so they still need a color of their own
        extend(hl, "diffSubname", vim.tbl_extend("force", emphasis, { fg = c.blue }))
        extend(hl, "gitdiff", vim.tbl_extend("force", emphasis, { fg = c.blue }))

        extend(hl, "DiffText", { bg = c.diff.text, fg = contrast_fg(c.diff.text), bold = true })

        -- GitSignsAdd/Change/Delete already use c.git; the staged variants are
        -- missing, dimmed toward the background
        extend(hl, "GitSignsStagedAdd", { fg = blend(c.git.add, 0.5, c.bg) })
        extend(hl, "GitSignsStagedChange", { fg = blend(c.git.change, 0.5, c.bg) })
        extend(hl, "GitSignsStagedDelete", { fg = blend(c.git.delete, 0.5, c.bg) })

        for _, group in ipairs({ "fugitiveUnstagedSection", "fugitiveStagedSection" }) do
          extend(hl, group, vim.tbl_extend("force", emphasis, { fg = c.purple }))
        end

        -- flog's graph groups default-link to generic syntax colors; follow git's
        -- --decorate conventions to match fugitive. flogDiff* already links to diff*.
        extend(hl, "flogHash", { fg = c.magenta })
        extend(hl, "flogAuthor", { fg = c.teal })
        extend(hl, "flogDate", { fg = c.dark5 })
        extend(hl, "flogRef", { fg = c.blue })
        extend(hl, "flogRefTag", { fg = c.yellow, bold = true })
        extend(hl, "flogRefRemote", { fg = c.red, bold = true })
        extend(hl, "flogRefHead", { fg = c.cyan, bold = true })
        extend(hl, "flogRefHeadBranch", { fg = c.green, bold = true })
        extend(hl, "flogCollapsedCommit", { fg = c.comment, italic = true })
        hl.FugitiveDeltaText = { link = "DiffText" }
      end,
    },
  },

  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      set_dark_mode = function()
        vim.notify("Enabling dark mode 🌚")
        vim.api.nvim_set_option_value("background", "dark", {})
        vim.cmd("colorscheme tokyonight-storm")
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
