return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()

      keys[#keys + 1] = { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "Goto Definition", has = "definition" }
      keys[#keys + 1] = { "gI", "<cmd>Telescope lsp_implementations<cr>", desc = "Goto Implementation" }
      keys[#keys + 1] = { "gy", "<cmd>Telescope lsp_type_definitions<cr>", desc = "Goto T[y]pe Definition" }
      keys[#keys + 1] = {
        "gr",
        function()
          require("trouble").open("lsp_references")
        end,
        desc = "References",
      }
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = { "onsails/lspkind.nvim" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local lspkind = require("lspkind")
      opts.formatting = {
        format = lspkind.cmp_format({
          mode = "text_symbol",
          -- maxwidth = 50,
          ellipsis_char = "...",

          -- The function below will be called before any actual modifications from lspkind
          -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
          before = function(entry, vim_item)
            -- ...
            return vim_item
          end,
        }),
      }
    end,
  },
}
