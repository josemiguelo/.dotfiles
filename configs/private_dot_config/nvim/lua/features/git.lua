local get_window_by_ft = require("util.windows").get_window_by_ft

-- :G outside a repository is an echoerr (a Lua error from a mapping); say so instead.
local function open_fugitive()
  if vim.fn.FugitiveGitDir() == "" then
    vim.notify("Not a git repository: " .. vim.fn.getcwd(), vim.log.levels.WARN, { title = "Fugitive" })
    return
  end
  vim.cmd("G")
end

local function fugitive_toggle_window()
  local fugitive_win = get_window_by_ft("fugitive")
  if fugitive_win then
    vim.api.nvim_win_close(fugitive_win, true)
  else
    open_fugitive()
  end
end

return {
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fugitive",
        callback = function(ev)
          vim.keymap.set("n", "<Leader><CR>", "gO", {
            buffer = ev.buf,
            remap = true,
            silent = true,
            desc = "Fugitive: open file under cursor in vertical split",
          })
        end,
      })

      -- the hunk-header emphasis (FugitiveHunkHeader/Context, colorscheme.lua) only
      -- applies in the status window: commit, blame and flog diffs share diffLine
      -- and diffSubname, so map them per window rather than globally
      local hunk_map = "diffLine:FugitiveHunkHeader,diffSubname:FugitiveHunkContext"
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        callback = function(ev)
          if vim.bo[ev.buf].filetype == "fugitive" then
            vim.wo.winhighlight = hunk_map
          elseif vim.wo.winhighlight == hunk_map then
            vim.wo.winhighlight = ""
          end
        end,
      })
    end,
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gvdiffsplit",
      "Gedit",
      "Gsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "Glgrep",
      "Gmove",
      "Gdelete",
      "GRemove",
      "Gbrowse",
    },
    keys = {
      {
        "<leader>gg",
        function()
          if vim.v.count > 0 then
            open_fugitive()
          else
            fugitive_toggle_window()
          end
        end,
        desc = "GitUi (Root Dir)",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "diff",
        "git_config",
        "git_rebase",
        "gitcommit",
        "gitattributes",
        "gitignore",
      },
    },
  },

  {
    "rbong/vim-flog",
    event = "VeryLazy",
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = { "tpope/vim-fugitive" },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "floggraph",
        callback = function(ev)
          vim.keymap.set("n", "<Leader><CR>", "<Cmd>belowright Flogsplitcommit<CR>", {
            buffer = ev.buf,
            silent = true,
            desc = "Flog: open commit in horizontal split below",
          })
        end,
      })
    end,
  },
  {
    "tpope/vim-rhubarb",
    event = "VeryLazy",
  },
  {
    "shumphrey/fugitive-gitlab.vim",
    event = "VeryLazy",
  },
  {
    "farhanmustar/fugitive-delta.nvim",
    event = "VeryLazy",
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "▌" },
        change = { text = "▌" },
        delete = { text = "▌" },
        topdelete = { text = "▌" },
        changedelete = { text = "▌" },
        untracked = { text = "▌" },
      },
      signs_staged = {
        add = { text = "▌" },
        change = { text = "▌" },
        delete = { text = "▌" },
        topdelete = { text = "▌" },
        changedelete = { text = "▌" },
      },
    },
  },
}
