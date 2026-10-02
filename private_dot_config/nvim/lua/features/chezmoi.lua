-- chezmoi.nvim's options under their current names (events.*.notification).
-- LazyVim's chezmoi extra (lazyvim.json) still sets the older `notification`
-- table, which chezmoi.nvim ignores, so its "will be automatically applied"
-- popup showed on every open of a source file.
return {
  {
    "xvzc/chezmoi.nvim",
    opts = {
      events = {
        on_open = { notification = { enable = true } },
        on_watch = { notification = { enable = false } },
        on_apply = { notification = { enable = true } },
      },
    },
  },
}
