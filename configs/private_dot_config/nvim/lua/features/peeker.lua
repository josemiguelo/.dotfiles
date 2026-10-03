return {
  "WilliamHsieh/overlook.nvim",
  config = function()
    require("overlook").setup({})

    -- stylua: ignore
    vim.keymap.set( "n", "<leader>po", require("overlook.api").open_in_original_window, { desc = "Open popup in current window" })
    vim.keymap.set("n", "<leader>pd", require("overlook.api").peek_definition, { desc = "Peek definition" })
    vim.keymap.set("n", "<leader>pp", require("overlook.api").peek_cursor, { desc = "Peek cursor" })
    vim.keymap.set("n", "<leader>pu", require("overlook.api").restore_popup, { desc = "Restore last popup" })
    vim.keymap.set("n", "<leader>pU", require("overlook.api").restore_all_popups, { desc = "Restore all popups" })
    vim.keymap.set("n", "<leader>pc", require("overlook.api").close_all, { desc = "Close all popups" })
    vim.keymap.set("n", "<leader>pf", require("overlook.api").switch_focus, { desc = "Switch focus" })
    vim.keymap.set("n", "<leader>ps", require("overlook.api").open_in_split, { desc = "Open popup in split" })
    vim.keymap.set("n", "<leader>pv", require("overlook.api").open_in_vsplit, { desc = "Open popup in vsplit" })
    vim.keymap.set("n", "<leader>pt", require("overlook.api").open_in_tab, { desc = "Open popup in tab" })
  end,
}
