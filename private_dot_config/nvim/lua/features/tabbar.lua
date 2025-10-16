return {
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },

  {
    "nanozuki/tabby.nvim",
    dependencies = {
      { "folke/tokyonight.nvim", "folke/snacks.nvim" },
    },
    config = function()
      vim.o.showtabline = 2

      local colors = require("tokyonight.colors").setup()

      local theme = {
        fill = "TabLineFill",
        current_tab = { fg = colors.black, bg = colors.blue, style = "bold" },
        tab = { style = "italic" },
      }

      local function is_zoomed()
        return Snacks.zen.win and Snacks.zen.win:valid() or false
      end

      local function get_file_name()
        local bufnr = vim.api.nvim_get_current_buf()
        local full_path = vim.api.nvim_buf_get_name(bufnr)
        local filename = vim.fn.fnamemodify(full_path, ":t")
        return filename
      end

      require("tabby.tabline").set(function(line)
        if is_zoomed() then
          return {
            line.spacer(),
            get_file_name() .. " [ZOOMED]",
            hl = theme.current_tab,
            margin = " ",
            line.spacer(),
          }
        else
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
        end
      end)

      local map = vim.keymap.set
      local remap = require("util.keymaps").remap

      map("n", "<leader><tab>r", ":TabRename ", { desc = "Rename tab" })
      map("n", "<leader><tab>e", "<cmd>tab split<cr>", { desc = "Edit current in new Tab" })
      map("n", "<leader><tab>m", "<cmd>tabm +1<cr>", { desc = "Move current tab to the right" })
      map("n", "<leader><tab>M", "<cmd>tabm -1<cr>", { desc = "Move current tab to the right" })
      map("n", "<leader><tab>r", ":TabRename ", { desc = "Rename tab" })

      LazyVim.on_very_lazy(function()
        Snacks.toggle
          .new({
            id = "zoom",
            name = "Zoom Mode",
            get = function()
              return Snacks.zen.win and Snacks.zen.win:valid() or false
            end,
            set = function(state)
              if state then
                Snacks.zen.zoom({ zoom = { win = { width = vim.o.columns } } })
              elseif Snacks.zen.win then
                Snacks.zen.win:close()
              end
            end,
          })
          :map("<leader>wm")
          :map("<leader>uZ")

        remap("n", "<S-l>", "<cmd>tabnext<cr>", { desc = "Next Tab" })
        remap("n", "<S-h>", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
      end)
    end,
  },
}
