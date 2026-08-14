return {
  -- kanata type
  {
    "kmonad/kmonad-vim",
    init = function()
      vim.filetype.add({ extension = { kbd = "kanata" } })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "kanata",
        callback = function()
          vim.bo.syntax = "kmonad"
        end,
      })
    end,
  },
}
