local Util = require("lazyvim.util")

return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>gs", vim.NIL },
      { "<leader>gc", vim.NIL },
      { "<leader>ss", vim.NIL },
      { "<leader>fF", Util.telescope("files"), desc = "Find Files (root dir)" },
      { "<leader>ff", Util.telescope("files", { cwd = false }), desc = "Find Files (cwd)" },
      { "<leader>sg", Util.telescope("live_grep", { cwd = false }), desc = "Grep (cwd)" },
      { "<leader>sG", Util.telescope("live_grep"), desc = "Grep (root dir)" },
      { "<leader>fR", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
      { "<leader>fr", Util.telescope("oldfiles", { cwd = vim.loop.cwd() }), desc = "Recent (cwd)" },
    },
    dependencies = {
      {
        "olimorris/persisted.nvim",
        lazy = false,
        opts = {
          use_git_branch = true,
          follow_cwd = false,
          autosave = true,
          allowed_dirs = {
            "~/.config/nvim",
          },
        },
        config = function(_, opts)
          local wk = require("which-key")
          local keys = { mode = { "n" }, ["<leader>z"] = { name = "+Sessions" } }
          wk.register(keys)

          require("persisted").setup(opts)
          require("telescope").load_extension("persisted")
        end,
        keys = {
          { "<leader>zz", "<Cmd>Telescope persisted<CR>", desc = "List session" },
          { "<leader>zs", "<Cmd>SessionSave<CR>", desc = "Save session" },
        },
      },
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
            desc = "List session",
          },
        },
      },
      {
        "nvim-telescope/telescope-file-browser.nvim",
        opts = {},
        config = function(_, opts)
          require("telescope").load_extension("file_browser")
        end,
        keys = {
          { "<leader>fe", "<Cmd>Telescope file_browser<CR>", desc = "File browser project" },
          {
            "<leader>fE",
            "<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>",
            desc = "File browser buffer",
          },
        },
      },
    },
    opts = {
      defaults = {
        vimgrep_arguments = {
          "rg",
          "-L",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
        },
        prompt_prefix = "   ",
        selection_caret = "  ",
        entry_prefix = "  ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.5,
            results_width = 0.8,
          },
          vertical = {
            mirror = false,
          },
          width = 0.95,
          height = 0.95,
          preview_cutoff = 120,
        },
        file_sorter = require("telescope.sorters").get_fuzzy_file,
        file_ignore_patterns = { "node_modules" },
        generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
        path_display = { "truncate" },
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
        mappings = {
          n = { ["q"] = require("telescope.actions").close },
        },
      },
    },
  },
}
