local LazyCoreUtil = require("lazy.core.util")
local LazyVimUtil = require("lazyvim.util")

return {
  {
    "folke/todo-comments.nvim",
    opts = {
      search = {
        pattern = [[\b(KEYWORDS):]], -- ripgrep regex
        -- pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
      },
    },
  },

  {
    "NvChad/nvim-colorizer.lua",
    config = true,
  },

  {
    "LunarVim/bigfile.nvim",
    opts = {
      pattern = function(bufnr, filesize_mib)
        local name = vim.api.nvim_buf_get_name(bufnr)

        if name:find("^fugitive:") ~= nil then
          return false
        end

        -- you can't use `nvim_buf_line_count` because this runs on BufReadPre
        local file_contents = vim.fn.readfile(name)
        local file_length = #file_contents
        local filetype = vim.filetype.match({ buf = bufnr })

        -- json
        if file_length > 5000 and filetype == "json" then
          LazyCoreUtil.info("Disabling features on big json..")
          return true
        end

        return false
      end,
      features = { -- features to disable
        "indent_blankline",
        "illuminate",
        "lsp",
        "treesitter",
        "matchparen",
      },
    },
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    config = function(opts)
      vim.opt.list = true
      vim.opt.listchars:append("space:⋅")
      vim.opt.listchars:append("eol:↴")

      require("ibl").setup(opts.opts)
    end,
  },

  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerToggle",
      "OverseerRun",
    },
    keys = {
      { "<leader>rt", "<Cmd>:OverseerToggle<CR>", desc = "Toggle Overseer" },
      { "<leader>rr", "<Cmd>:OverseerRun<CR>", desc = "Toggle Overseer" },
    },
    opts = {
      templates = {
        "builtin",
      },
      task_list = {
        bindings = {
          ["?"] = "ShowHelp",
          ["g?"] = "ShowHelp",
          ["<CR>"] = "RunAction",
          ["<C-e>"] = "Edit",
          ["o"] = "Open",
          ["<C-v>"] = "OpenVsplit",
          ["<C-s>"] = "OpenSplit",
          ["<C-f>"] = "OpenFloat",
          ["<C-q>"] = "OpenQuickFix",
          ["p"] = "TogglePreview",
          ["<C-l>"] = "IncreaseDetail",
          ["<C-h>"] = "DecreaseDetail",
          ["L"] = false,
          ["H"] = false,
          ["["] = "DecreaseAllDetail",
          ["]"] = "IncreaseAllDetail",
          ["{"] = "PrevTask",
          ["}"] = "NextTask",
          ["<C-k>"] = "ScrollOutputUp",
          ["<C-j>"] = "ScrollOutputDown",
        },
      },
    },
    config = function(_, opts)
      local overseer = require("overseer")
      overseer.setup(opts)

      pcall(require, "private.overseer")
    end,
  },

  {
    "nvim-pack/nvim-spectre",
    config = function()
      local keys = {
        ["<leader>sr"] = { name = "+Spectre" },
      }
      require("which-key").register(keys)
    end,
    keys = {
      { "<leader>sr", vim.NIL },
      {
        "<leader>srR",
        '<cmd>lua require("spectre").open()<CR>',
        desc = "Open",
      },
      {
        "<leader>srw",
        '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
        desc = "Search current word",
      },
      {
        "<leader>srw",
        '<esc><cmd>lua require("spectre").open_visual()<CR>',
        desc = "Search selection",
        mode = "v",
      },
      {
        "<leader>srr",
        '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
        desc = "Search current word on current file",
      },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>gs", vim.NIL },
      { "<leader>gc", vim.NIL },
      { "<leader>ss", vim.NIL },
      { "<leader>fF", LazyVimUtil.telescope("files"), desc = "Find Files (root dir)" },
      { "<leader>ff", LazyVimUtil.telescope("files", { cwd = false }), desc = "Find Files (cwd)" },
      { "<leader>sg", LazyVimUtil.telescope("live_grep", { cwd = false }), desc = "Grep (cwd)" },
      { "<leader>sG", LazyVimUtil.telescope("live_grep"), desc = "Grep (root dir)" },
      { "<leader>fR", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
      { "<leader>fr", LazyVimUtil.telescope("oldfiles", { cwd = vim.loop.cwd() }), desc = "Recent (cwd)" },
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
        file_ignore_patterns = { "node_modules" },
        path_display = { "truncate" },
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
      },
    },
  },
}
