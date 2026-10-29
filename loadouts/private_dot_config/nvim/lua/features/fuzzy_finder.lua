local custom_vertical_layout = {
  layout = {
    layout = {
      backdrop = false,
      width = 0.9,
      min_width = 80,
      height = 0.9,
      min_height = 20,
      box = "vertical",
      border = "rounded",
      title = "{title} {live} {flags}",
      title_pos = "center",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
      { win = "preview", title = "{preview}", height = 0.8, border = "top" },
    },
  },
}

-- A grep row is the path, then the matched text. The path gets a share of the
-- list's width (the rest is the text's), so a narrow window still shows the
-- match: snacks gives the path whatever the text leaves, down to a fixed
-- `min_width`, so give it the same share always and let that floor go (see the
-- source).
local grep_path_share = 0.6
local grep_path_min = 40 -- narrower clips the file name itself

-- Colors: the whole path reads like the file name, and the matched text is
-- dimmed (the colorscheme's dirname color) except the match itself, so what
-- was searched for stands out. The line's own syntax colors go.
local function grep_format(item, picker)
  local ret = Snacks.picker.format.file(item, picker)
  local win = picker.list and picker.list.win and picker.list.win.win
  local width = win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_width(win) or vim.o.columns
  local cap = math.max(math.floor(width * grep_path_share), grep_path_min)

  local rest = {} ---@type snacks.picker.Highlight[]
  local matches = {} ---@type snacks.picker.Highlight[]
  for _, part in ipairs(ret) do
    if part.resolve then
      local resolve = part.resolve
      part.resolve = function()
        local path = resolve(cap)
        local base = path[#path]
        for _, dir in ipairs(path) do
          if dir[2] == "SnacksPickerDir" then
            dir[2] = base[2]
          end
        end
        return path
      end
    end
    if part[1] == nil and part.hl_group == "SnacksPickerMatch" then
      part.priority = 5000 -- over the dimmed text's default 4096
      matches[#matches + 1] = part
    elseif part[1] ~= nil or part.virt_text then
      if item.line and part[1] == item.line then
        part[2] = "SnacksPickerDir"
      end
      rest[#rest + 1] = part
    end -- else: the line's syntax highlight
  end
  vim.list_extend(rest, matches)
  return rest
end

local grep_source = vim.tbl_extend("force", custom_vertical_layout, {
  format = grep_format,
  formatters = { file = { min_width = 1 } },
})

-- From a float, `wincmd` goes to the previous window whatever the direction,
-- so vim-tmux-navigator never sees the explorer list at nvim's edge. Navigate
-- from the explorer's sidebar split (its layout root) instead.
local function tmux_navigate(direction)
  return function(picker)
    vim.api.nvim_win_call(picker.layout.root.win, function()
      vim.cmd("TmuxNavigate" .. direction)
    end)
  end
end

local custom_explorer_layout = {
  -- Hidden and ignored files always show (H and I still flip them).
  hidden = true,
  ignored = true,
  layout = {
    layout = {
      width = 50,
      min_width = 50,
      position = "left",
      box = "vertical",
      {
        win = "input",
        height = 1,
        border = "none",
        title = "{title} {live} {flags}",
        title_pos = "center",
      },
      { win = "list", border = "none" },
    },
  },
  actions = {
    tmux_left = tmux_navigate("Left"),
    tmux_down = tmux_navigate("Down"),
    tmux_up = tmux_navigate("Up"),
  },
  win = {
    list = {
      keys = {
        ["<c-h>"] = "tmux_left",
        ["<c-j>"] = "tmux_down",
        ["<c-k>"] = "tmux_up",
      },
    },
  },
}

-- Repos whose files and grep show hidden files: in the dotfiles half the
-- files are under dot entries (loadout's `.<tool>.loadout.kt` and `.loadout/`,
-- `.etc/`, `.chezmoitemplates/`), which they'd skip. A repo's worktrees count
-- as the repo. .git stays out and .gitignore still applies; elsewhere hidden
-- files stay hidden. <a-h> in the picker flips it.
local show_hidden_repos = {
  "~/.local/share/chezmoi",
}

-- The main checkout of the repo `dir` is in (a worktree's, for a worktree),
-- or nil outside one.
local function main_checkout(dir)
  local root = vim.fs.root(dir, ".git")
  if not root then
    return nil
  end
  local git = root .. "/.git"
  if vim.fn.isdirectory(git) == 1 then
    return root
  end
  -- A worktree's .git is a file: "gitdir: <main>/.git/worktrees/<name>".
  local line = (vim.fn.readfile(git, "", 1))[1] or ""
  return line:match("^gitdir: (.*)/%.git/worktrees/[^/]+$") or root
end

local function shows_hidden(dir)
  local repo = main_checkout(dir)
  if not repo then
    return false
  end
  repo = vim.fs.normalize(repo)
  for _, path in ipairs(show_hidden_repos) do
    if vim.fs.normalize(path) == repo then
      return true
    end
  end
  return false
end

local function pick(source, opts)
  opts = opts or {}
  return function()
    local o = vim.deepcopy(opts)
    local dir = o.root == false and vim.fn.getcwd() or LazyVim.root()
    if o.hidden == nil and shows_hidden(dir) then
      o.hidden = true
    end
    LazyVim.pick(source, o)()
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {},
      explorer = {},
    },
    -- stylua: ignore
    keys = {
      { "<leader>fF", pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>ff", pick("files", { root = false }), desc = "Find Files (cwd)" },

      { "<leader>fR", LazyVim.pick("oldfiles"), desc = "Recent" },
      { "<leader>fr", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "Recent (cwd)" },

      { "<leader>sG", pick("live_grep"), desc = "Grep (Root Dir)" },
      { "<leader>sg", pick("live_grep", { root = false }), desc = "Grep (cwd)" },

      { "<leader><space>", pick("files", { root = false }), desc = "Find Files (cwd)" },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          smart = custom_vertical_layout,
          grep = grep_source,
          explorer = custom_explorer_layout,
          files = custom_vertical_layout,
          buffers = custom_vertical_layout,
          notifications = custom_vertical_layout,
          oldfiles = custom_vertical_layout,
          recent = custom_vertical_layout,
          help = custom_vertical_layout,
          lsp_references = custom_vertical_layout,
          lsp_symbols = custom_vertical_layout,
          lsp_definitions = custom_vertical_layout,
          lsp_implementations = custom_vertical_layout,
          lsp_type_definitions = custom_vertical_layout,
          lsp_workspace_symbols = custom_vertical_layout,
          lsp_incoming_calls = custom_vertical_layout,
          lsp_outgoing_calls = custom_vertical_layout,
        },
      },
    },
  },
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
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
}
