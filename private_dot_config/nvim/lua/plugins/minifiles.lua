return {
  "echasnovski/mini.files",
  enabled = false,
  opts = {
    windows = {
      width_focus = 40,
      width_preview = 30,
    },
    options = {
      use_as_default_explorer = true,
      permanent_delete = false,
    },
  },
  keys = {
    {
      "<leader>E",
      function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = "Open mini.files (current file)",
    },
    {
      "<leader>e",
      function()
        require("mini.files").open(vim.loop.cwd(), true)
      end,
      desc = "Open mini.files (cwd)",
    },
  },
  config = function(_, opts)
    require("mini.files").setup(opts)

    local show_dotfiles = true
    local filter_show = function(fs_entry)
      return true
    end
    local filter_hide = function(fs_entry)
      return not vim.startswith(fs_entry.name, ".")
    end

    local toggle_dotfiles = function()
      show_dotfiles = not show_dotfiles
      local new_filter = show_dotfiles and filter_show or filter_hide
      require("mini.files").refresh({ content = { filter = new_filter } })
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        local buf_id = args.data.buf_id
        -- Tweak left-hand side of mapping to your liking
        vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id })
      end,
    })
  end,
}
