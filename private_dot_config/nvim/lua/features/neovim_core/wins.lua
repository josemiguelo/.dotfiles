local create_augroup = require("util.cmds").new_lazyvim_augroup
local delete_augroup = require("util.cmds").del_lazyvim_augroup

local suffix = "close_with_q"

LazyVim.on_very_lazy(function()
  delete_augroup(suffix) -- remove original command

  vim.api.nvim_create_autocmd("FileType", {
    group = create_augroup("custom_" .. suffix),
    pattern = { -- add more filetypes to close with q
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
      "fugitive",
      "fugitiveblame",
    },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.schedule(function()
        local action_close = function()
          vim.cmd("close")
          pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
        end
        local keymap_options = { buffer = event.buf, silent = true, desc = "Quit buffer" }
        vim.keymap.set("n", "q", action_close, keymap_options)
      end)
    end,
  })
end)

vim.opt.splitkeep = "cursor"

return {
  {
    "folke/which-key.nvim",
    -- stylua: ignore
    keys = {
      { "<C-Up>", mode = { "n" }, "<cmd>resize +10<cr>", desc = "Increase Window Height", },
      { "<C-Down>", mode = { "n" }, "<cmd>resize -10<cr>", desc = "Decrease Window Height", },
      { "<C-Left>", mode = { "n" }, "<cmd>vertical resize -10<cr>", desc = "Decrease Window Width", },
      { "<C-Right>", mode = { "n" }, "<cmd>vertical resize +10<cr>", desc = "Increase Window Width", },
    },
  },
}
