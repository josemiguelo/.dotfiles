return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<leader>fe", vim.NIL },
      { "<leader>fE", vim.NIL },
      { "<leader>e", vim.NIL },
      { "<leader>E", vim.NIL },
    },
    dependencies = {
      {
        "s1n7ax/nvim-window-picker",
        name = "window-picker",
        event = "VeryLazy",
        version = "2.*",
        config = function()
          require("window-picker").setup({
            filter_rules = {
              include_current_win = false,
              autoselect_one = true,
              -- filter using buffer options
              bo = {
                -- if the file type is one of following, the window will be ignored
                filetype = { "neo-tree", "neo-tree-popup", "notify" },
                -- if the buffer type is one of following, the window will be ignored
                buftype = { "terminal", "quickfix" },
              },
            },
          })
        end,
      },
    },
  },

  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = { { "<leader>e", "<cmd>Oil --float<CR>", desc = "Oil file manager" } },
    init = function()
      if vim.fn.argc(-1) == 1 then
        local stat = vim.loop.fs_stat(vim.fn.argv(0))
        if stat and stat.type == "directory" then
          vim.cmd("Oil")
        end
      end
    end,
    opts = {
      columns = {
        "icon",
        { "mtime", highlight = "Comment", format = "%T %y-%m-%d" },
      },
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = true,
      },
      float = {
        padding = 3,
        win_options = {
          winblend = 0,
        },
      },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-file-browser.nvim",
        opts = {},
        config = function()
          require("telescope").load_extension("file_browser")
        end,
        keys = {
          {
            "<leader>fe",
            "<Cmd>Telescope file_browser<CR>",
            desc = "File browser project",
          },
          {
            "<leader>fE",
            "<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>",
            desc = "File browser buffer",
          },
        },
      },
    },
  },
}
