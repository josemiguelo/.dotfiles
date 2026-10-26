vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.split(vim.lsp.log.get_filename())
end, { desc = "Get all the lsp logs" })

vim.api.nvim_create_user_command("LspInfo", function()
  vim.cmd("silent checkhealth vim.lsp")
end, { desc = "Get all the information about all LSP attached" })

return {
  {
    -- noice draws K's hover and the signature help, borderless by default
    "folke/noice.nvim",
    opts = {
      presets = { lsp_doc_border = true },
    },
  },
}
