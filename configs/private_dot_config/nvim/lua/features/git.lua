local get_window_by_ft = require("util.windows").get_window_by_ft

-- fugitive lives alone in the first tab, named "git": go to it from another tab,
-- refresh it from its own, or open it there. The new tab splits off the current
-- buffer so fugitive finds that buffer's repo, which the status then replaces.
local function open_fugitive()
  local fugitive_win = get_window_by_ft("fugitive")
  if fugitive_win then
    local on_its_tab = vim.api.nvim_win_get_tabpage(fugitive_win) == vim.api.nvim_get_current_tabpage()
    vim.api.nvim_set_current_win(fugitive_win)
    if on_its_tab then
      vim.cmd("G")
    end
    return
  end
  -- :G outside a repository is an echoerr (a Lua error from a mapping); say so instead.
  if vim.fn.FugitiveGitDir() == "" then
    vim.notify("Not a git repository: " .. vim.fn.getcwd(), vim.log.levels.WARN, { title = "Fugitive" })
    return
  end
  vim.cmd("tab split | tabmove 0 | Gedit :")
  -- what :G marks its window with: fugitive's <CR> then opens files in another
  -- window rather than over the status, splitting one off below when it's alone
  vim.w.fugitive_status = vim.fn.FugitiveGitDir()
  require("tabby.feature.tab_name").set(0, "git")
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

      -- commit buffers (Gclog, Flogsplitcommit) open with each file's diff folded
      -- to one line, its status letter and path, like the status window
      -- (util/git_foldtext.lua); the git syntax already marks each file as a fold,
      -- but init.lua's global foldmethod and foldtext hide it. The status
      -- window's keys work on them: = toggles, > opens, < closes, ]m [m ]/ [/ close
      -- the file they leave, and ( ) step over a closed file as one item rather than
      -- opening it (fugitive's own ]c [c open the one they reach)
      local function fold(cmd)
        return function()
          pcall(vim.cmd.normal, { cmd, bang = true }) -- E490 outside a file's diff
        end
      end
      local function jump_file(flags)
        return function()
          for _ = 1, vim.v.count1 do
            if vim.fn.foldclosed(".") == -1 and vim.fn.foldlevel(".") > 0 then
              vim.cmd.normal({ "zc", bang = true })
            end
            if vim.fn.search("^diff ", flags) == 0 then
              break
            end
          end
        end
      end
      -- fugitive's item pattern (files, hunks, commits), searched from past a closed
      -- file going forward, and landing on its first line going back
      local item_pattern = [[^[A-Z?] .\|^diff --\|^\%(\l\{3,\} \)\=[0-9a-f]\{4,\} \|^@@]]
      local function jump_item(backward)
        local flags = backward and "bW" or "W"
        return function()
          for _ = 1, vim.v.count1 do
            local edge = backward and vim.fn.foldclosed(".") or vim.fn.foldclosedend(".")
            vim.fn.cursor(edge ~= -1 and edge or vim.fn.line("."), 1)
            local lnum = vim.fn.search(item_pattern, flags)
            if lnum == 0 then
              lnum = vim.fn.search("^commit ", flags)
            end
            if lnum == 0 then
              break
            end
            if vim.fn.foldclosed(lnum) ~= -1 then
              vim.fn.cursor(vim.fn.foldclosed(lnum), 1)
            end
          end
        end
      end
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "git",
        callback = function(ev)
          vim.opt_local.foldmethod = "syntax"
          vim.opt_local.foldtext = "v:lua.require'util.git_foldtext'.foldtext()"
          vim.opt_local.foldlevel = 0
          -- no closed-fold icon beside the line number: the letter marks the file
          vim.opt_local.fillchars = vim.tbl_extend("force", vim.opt.fillchars:get(), { foldclose = " " })
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, silent = true, desc = "Fugitive: " .. desc })
          end
          map("=", fold("za"), "toggle the file's diff under cursor")
          map(">", fold("zo"), "open the file's diff under cursor")
          map("<", fold("zc"), "close the file's diff under cursor")
          map("]m", jump_file("W"), "next file, closing this one")
          map("[m", jump_file("bW"), "previous file, closing this one")
          map("]/", jump_file("W"), "next file, closing this one")
          map("[/", jump_file("bW"), "previous file, closing this one")
          map(")", jump_item(false), "next file or hunk, without opening it")
          map("(", jump_item(true), "previous file or hunk, without opening it")
        end,
      })
      -- picking a commit in Gclog's quickfix list puts the cursor back where it was in
      -- that commit, and foldopen's "quickfix" opens the file it lands in: leave it
      -- out while a commit is being shown, until the jump is done
      vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function(ev)
          if vim.bo[ev.buf].filetype ~= "git" or not vim.o.foldopen:find("quickfix") then
            return
          end
          local foldopen = vim.o.foldopen
          vim.opt.foldopen:remove("quickfix")
          vim.schedule(function()
            vim.o.foldopen = foldopen
          end)
        end,
      })

      -- the hunk-header emphasis (FugitiveHunkHeader/Context, colorscheme.lua) only
      -- applies in the status window: commit, blame and flog diffs share diffLine
      -- and diffSubname, so map them per window rather than globally. Commit
      -- buffers drop Folded's band, so a closed file reads like a status line
      local winhighlights = {
        fugitive = "diffLine:FugitiveHunkHeader,diffSubname:FugitiveHunkContext",
        git = "Folded:Normal",
      }
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        callback = function(ev)
          local winhighlight = winhighlights[vim.bo[ev.buf].filetype]
          if winhighlight then
            vim.wo.winhighlight = winhighlight
          elseif vim.tbl_contains(vim.tbl_values(winhighlights), vim.wo.winhighlight) then
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
      { "<leader>gg", open_fugitive, desc = "GitUi (Root Dir)" },
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
