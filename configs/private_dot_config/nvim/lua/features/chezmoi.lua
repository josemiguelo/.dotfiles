-- LazyVim's chezmoi extra (lazyvim.json) knows one source, the main checkout:
-- its auto-apply only fires under ~/.local/share/chezmoi/, and its picker
-- always lists and opens that checkout's files. This layers on feature
-- worktrees (workmux, at ~/.local/share/chezmoi__worktrees/<feature>):
-- opening a file there says that saving doesn't apply it, and when nvim's cwd
-- is inside one, <leader>sz and the dashboard's `c` list and open the
-- worktree's source files, without auto-apply. Outside a worktree both behave
-- like the extra's. It also sets chezmoi.nvim's options under their current
-- names (events.*.notification); the extra's `notification` table is from an
-- older chezmoi.nvim, so its "will be automatically applied" popup showed on
-- every open.

local worktrees = vim.env.HOME .. "/.local/share/chezmoi__worktrees/"

-- The feature worktree a path is inside, as (root, name), or nil.
local function worktree_of(path)
  if path:sub(1, #worktrees) ~= worktrees then
    return nil
  end
  local name = path:sub(#worktrees + 1):match("^[^/]+")
  if not name then
    return nil
  end
  return worktrees .. name, name
end

local list_args = { "--path-style", "absolute", "--include", "files", "--exclude", "externals" }

-- In a worktree: its managed targets; picking one opens its source file there.
local function pick_worktree(root, name)
  local results = require("chezmoi.commands").list({ args = vim.list_extend({ "--source", root }, list_args) })
  local items = {}
  for _, target in ipairs(results) do
    table.insert(items, { text = target, file = target })
  end
  Snacks.picker.pick({
    title = "Chezmoi (" .. name .. ")",
    items = items,
    confirm = function(picker, item)
      picker:close()
      local source = vim.fn.systemlist({ "chezmoi", "--source", root, "source-path", item.text })[1]
      if vim.v.shell_error ~= 0 or not source then
        vim.notify("chezmoi couldn't find the source of " .. item.text, vim.log.levels.ERROR, { title = "Chezmoi" })
        return
      end
      vim.cmd.edit(vim.fn.fnameescape(source))
    end,
  })
end

-- The extra's snacks picker, for the main checkout.
local function pick_main()
  local results = require("chezmoi.commands").list({ args = vim.deepcopy(list_args) })
  local items = {}
  for _, target in ipairs(results) do
    table.insert(items, { text = target, file = target })
  end
  Snacks.picker.pick({
    items = items,
    confirm = function(picker, item)
      picker:close()
      require("chezmoi.commands").edit({ targets = { item.text }, args = { "--watch" } })
    end,
  })
end

local function pick_chezmoi()
  local root, name = worktree_of(vim.fn.getcwd())
  if root then
    pick_worktree(root, name)
  else
    pick_main()
  end
end

-- Once per buffer: a worktree's files aren't auto-applied on save.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("chezmoi_worktrees", { clear = true }),
  pattern = { worktrees .. "*" },
  callback = function(ev)
    if vim.b[ev.buf].chezmoi_worktree_notified then
      return
    end
    local root, name = worktree_of(vim.api.nvim_buf_get_name(ev.buf))
    if not root then
      return
    end
    vim.b[ev.buf].chezmoi_worktree_notified = true
    vim.notify(
      "Feature worktree " .. name .. ": saving doesn't apply this file. Try it with\nchezmoi --source " .. root .. " diff",
      vim.log.levels.INFO,
      { title = "Chezmoi" }
    )
  end,
})

-- chezmoi.vim types a template source <lang>.chezmoitmpl. Treesitter parses
-- it as <lang> alone, so the {{ }} parts break a strict format (a JSON
-- template is one parse error, left unhighlighted), and while Treesitter
-- highlights a buffer, chezmoi.vim's {{ }} syntax is off. Templates get Vim's
-- syntax highlighting instead, <lang> and chezmoitmpl together. Only the
-- highlighter stops: the parser stays, so render-markdown still renders
-- markdown templates.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("chezmoi_templates", { clear = true }),
  pattern = "*.chezmoitmpl",
  callback = function(ev)
    -- After the FileType handler that starts Treesitter.
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      vim.treesitter.stop(ev.buf)
      vim.bo[ev.buf].syntax = vim.bo[ev.buf].filetype
    end)
  end,
})

return {
  {
    "xvzc/chezmoi.nvim",
    keys = {
      { "<leader>sz", pick_chezmoi, desc = "Chezmoi" },
    },
    opts = {
      events = {
        on_open = { notification = { enable = true } },
        on_watch = { notification = { enable = false } },
        on_apply = { notification = { enable = true } },
      },
    },
  },
  {
    "folke/snacks.nvim",
    optional = true,
    opts = function(_, opts)
      for _, key in ipairs(opts.dashboard.preset.keys) do
        if key.key == "c" then
          key.action = pick_chezmoi
        end
      end
    end,
  },
}
