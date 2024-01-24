return {
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },

  {
    "fgheng/winbar.nvim",
    enabled = false,
    config = function()
      require("winbar").setup({
        enabled = true,
        icons = {
          seperator = "/",
        },
        exclude_filetype = {
          "fugitive",
          "lazyterm",
          "gitcommit",
        },
      })
    end,
  },

  {
    "utilyre/barbecue.nvim",
    dependencies = { "folke/tokyonight.nvim" },
    config = function()
      local colors = require("tokyonight.colors").setup()

      local opts = {
        show_navic = false,
        attach_navic = false,
        exclude_filetypes = { "netrw", "toggleterm" },
        show_modified = true,
        -- custom_section = function(bufnr, winnr)
        --   -- Copied from @akinsho's config
        --   local error_icon = "" -- '✗'
        --   local warning_icon = ""
        --   local info_icon = "" --  
        --   local hint_icon = "⚑" --  ⚑
        --   local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        --   local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        --   local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        --   local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
        --   local components = {}
        --   if errors > 0 then
        --     components[#components + 1] = { error_icon .. " " .. errors, "DiagnosticError" }
        --   end
        --
        --   if warnings > 0 then
        --     components[#components + 1] =
        --       { (#components > 0 and " " or "") .. warning_icon .. " " .. warnings, "DiagnosticWarning" }
        --   end
        --
        --   if hints > 0 then
        --     components[#components + 1] =
        --       { (#components > 0 and " " or "") .. hint_icon .. " " .. hints, "DiagnosticHint" }
        --   end
        --
        --   if info > 0 then
        --     components[#components + 1] =
        --       { (#components > 0 and " " or "") .. info_icon .. " " .. info, "DiagnosticInfo" }
        --   end
        --
        --   return components
        -- end,
        theme = {
          -- normal = { bold = true, bg = colors.blue },
          normal = { bold = true, fg = colors.fg },
          -- dirname = { fg = colors.black },
          -- basename = { fg = colors.black },
          -- ellipsis = { fg = colors.black },
          -- separator = { fg = colors.black },
          -- modified = { fg = colors.black },
        },
      }
      require("barbecue").setup(opts)
    end,
  },

  {
    "nvimdev/dashboard-nvim",
    opts = function(_, opts)
      opts.config.header = vim.split(
        [[




 ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██ 
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░
   ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░   
         ░    ░  ░    ░ ░        ░   ░         ░   
                                ░                  

        ]],
        "\n"
      )
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = function()
      local icons = require("lazyvim.config").icons
      local Util = require("lazyvim.util").ui

      return {
        options = {
          theme = "auto",
          globalstatus = true,
          disabled_filetypes = { statusline = { "dashboard", "alpha" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            -- { "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
            -- stylua: ignore
            {
              function() return require("nvim-navic").get_location() end,
              cond = function() return package.loaded["nvim-navic"] and require("nvim-navic").is_available() end,
            },
          },
          lualine_x = {
            -- stylua: ignore
            {
              function() return require("noice").api.status.command.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
              color = Util.fg("Statement"),
            },
            -- stylua: ignore
            {
              function() return require("noice").api.status.mode.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
              color = Util.fg("Constant"),
            },
            -- stylua: ignore
            {
              function() return "  " .. require("dap").status() end,
              cond = function () return package.loaded["dap"] and require("dap").status() ~= "" end,
              color = Util.fg("Debug"),
            },
            { require("lazy.status").updates, cond = require("lazy.status").has_updates, color = Util.fg("Special") },
            {
              "diff",
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
            },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              local status_ok, _ = pcall(require, "maximize")
              if not status_ok then
                return
              end

              ---@diagnostic disable-next-line: undefined-field
              return vim.t.maximized and "   " or ""
            end,
          },
        },
        extensions = { "nvim-tree", "lazy" },
      }
    end,
  },

  {
    "nanozuki/tabby.nvim",
    dependencies = {
      { "folke/tokyonight.nvim" },
    },
    config = function()
      local colors = require("tokyonight.colors").setup()
      local theme = {
        fill = "TabLineFill",
        current_tab = { fg = colors.black, bg = colors.blue, style = "bold" },
        tab = { style = "italic" },
      }
      require("tabby.tabline").set(function(line)
        return {
          line.spacer(),
          line.tabs().foreach(function(tab)
            local hl = tab.is_current() and theme.current_tab or theme.tab
            return {
              line.sep(tab.is_current() and "" or "", hl, theme.fill),
              tab.number(),
              string.gsub(tab.name(), "%[..%]", ""),
              line.sep(tab.is_current() and " " or " ", hl, theme.fill),
              hl = hl,
              margin = " ",
            }
          end),
          line.spacer(),
        }
      end)
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "stevearc/aerial.nvim",
        dependencies = {
          "nvim-treesitter/nvim-treesitter",
          "nvim-tree/nvim-web-devicons",
        },
        config = function(_, opts)
          require("aerial").setup(opts)
          require("telescope").load_extension("aerial")
        end,
        keys = {
          { "<leader>na", "<cmd>AerialToggle!<cr>", desc = "Nav" },
          {
            "<leader>ss",
            function()
              require("telescope").extensions.aerial.aerial({ sorting_strategy = "descending" })
            end,
            desc = "List symbols",
          },
        },
      },
    },
  },
}
