local create_augroup = require("util.cmds").create_augroup
local delete_augroup = require("util.cmds").del_augroup
local get_window_by_ft = require("util.windows").get_window_by_ft

--[[
  add more filetypes to close with q
--]]
local suffix = "close_with_q"
delete_augroup(suffix) -- remove original command
vim.api.nvim_create_autocmd("FileType", {
  group = create_augroup(suffix),
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "dbout",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "git",
    "man",
    "scratch",
    "fugitive",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- TODO: jdtls toggle functionality

vim.opt.splitkeep = "cursor"

return {}
