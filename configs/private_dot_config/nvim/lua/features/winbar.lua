local winbar = require("util.winbar")

-- the buffer's path on a line of its own above the text (incline floated it over
-- the first line, hiding what a long path covered)
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "OptionSet", "WinNew", "WinClosed" }, {
  group = vim.api.nvim_create_augroup("file_winbar", { clear = true }),
  callback = function(ev)
    if ev.event == "OptionSet" and not vim.tbl_contains({ "buftype", "buflisted", "scrollbind" }, ev.match) then
      return
    end
    -- FileType and OptionSet can fire before the buffer is in a window
    vim.schedule(winbar.attach_all)
  end,
})

vim.keymap.set("n", "<leader>uW", winbar.toggle, { desc = "Toggle Winbar" })

return {}
