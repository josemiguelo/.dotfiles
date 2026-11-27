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
--
-- chezmoi's source is .chezmoi-home/, which loadout repo compile builds from the
-- tool folders (loadouts/<tool>/home/) as
-- symlinks to their files. A file you edit there is applied on save through
-- its symlink in the build; a tool's root/ files land in / as root, so saving
-- one says how to apply it instead.

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
      local source = vim.fn.systemlist({ "loadout", "--repo", root, "chezmoi", "source-path", item.text })[1]
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
      "Feature worktree " .. name .. ": saving doesn't apply this file. Try it with\nloadout --repo " .. root .. " chezmoi diff",
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

-- The extra's BufRead hook calls watch() on every file in the checkout, and
-- chezmoi refuses the save-time apply of a file outside its source. A file in
-- a tool's home/ is applied through its symlink in the build;
-- one in the build itself as it is; anything else (README.md, a manifest, a
-- script) isn't chezmoi's.
local checkout = vim.env.HOME .. "/.local/share/chezmoi/"
local build = checkout .. ".chezmoi-home/"

-- The path chezmoi knows a checkout file by (its place in the build), or nil.
local function build_path(path)
  if path:sub(1, #checkout) ~= checkout then
    return nil
  end
  local rel = path:sub(#checkout + 1)
  local inside = rel:match("^loadouts/[^/]+/home/(.+)$")
  if inside then
    return build .. inside
  end
  if path:sub(1, #build) == build then
    return path
  end
  return nil
end

-- A build's file is a symlink to the one in a tool folder: opening it
-- (fugitive's status, chezmoi edit, <leader>sz) lands on the real file, so
-- the buffer says what you're editing. A fugitive:// or diff buffer is left
-- alone: there the symlink is what's compared.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("chezmoi_build_files", { clear = true }),
  pattern = { "*/.chezmoi-home/*", "*/.chezmoi-root/*" },
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" or vim.wo.diff then
      return
    end
    local path = vim.api.nvim_buf_get_name(ev.buf)
    local stat = vim.uv.fs_lstat(path)
    local real = stat and stat.type == "link" and vim.uv.fs_realpath(path)
    if not real or real == path then
      return
    end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) or vim.bo[ev.buf].modified then
        return
      end
      -- Neovim takes both paths for one file, so :edit would stay on this
      -- buffer: it's renamed to the real path instead, and read again so
      -- BufRead hooks (the save-time apply) see that path.
      vim.api.nvim_buf_set_name(ev.buf, real)
      vim.api.nvim_buf_call(ev.buf, function()
        vim.cmd("silent edit!")
      end)
      local old = vim.fn.bufnr(path)
      if old ~= -1 and old ~= ev.buf then
        vim.api.nvim_buf_delete(old, { force = true })
      end
    end)
  end,
})

-- Saving a file in a tool folder applies it through the build: chezmoi only
-- knows the build's path for it.
local function watch_through_build(bufnr, source)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("chezmoi_build_" .. bufnr, { clear = true }),
    buffer = bufnr,
    callback = function()
      if not vim.uv.fs_lstat(source) then
        vim.notify("Not in chezmoi's source yet: run loadout repo compile", vim.log.levels.WARN, { title = "Chezmoi" })
        return
      end
      vim.system({ "chezmoi", "apply", "--source-path", source }, { text = true }, function(r)
        vim.schedule(function()
          if r.code == 0 then
            vim.notify("Applied", vim.log.levels.INFO, { title = "Chezmoi" })
          else
            vim.notify(r.stderr, vim.log.levels.WARN, { title = "Chezmoi" })
          end
        end)
      end)
    end,
  })
end

return {
  {
    -- chezmoi.vim types files under one source dir by chezmoi's names
    -- (.tmpl, dot_…). The files you edit are in the tool folders, not
    -- the build, so it gets the whole checkout: a template
    -- anywhere in it is typed as one. This init replaces the extra's
    -- (lazy.nvim keeps one).
    "alker0/chezmoi.vim",
    init = function()
      vim.g["chezmoi#use_tmp_buffer"] = 1
      vim.g["chezmoi#source_dir_path"] = checkout:sub(1, -2)
    end,
  },
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
    config = function(_, opts)
      require("chezmoi").setup(opts)
      local edit = require("chezmoi.commands.__edit")
      local watch = edit.watch
      edit.watch = function(bufnr, force)
        bufnr = bufnr or vim.api.nvim_get_current_buf()
        local path = vim.api.nvim_buf_get_name(bufnr)
        local tool = path:sub(1, #checkout) == checkout and path:sub(#checkout + 1):match("^loadouts/([^/]+)/root/")
        if tool then
          if not vim.b[bufnr].chezmoi_root_notified then
            vim.b[bufnr].chezmoi_root_notified = true
            vim.notify("A file outside $HOME: saving doesn't apply it. Run\nloadout config apply /" .. tool, vim.log.levels.INFO, { title = "Chezmoi" })
          end
          return
        end
        local source = build_path(path)
        if not source then
          return
        end
        if source == path then
          return watch(bufnr, force)
        end
        return watch_through_build(bufnr, source)
      end
    end,
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
