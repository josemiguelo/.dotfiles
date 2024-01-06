local g = vim.g
local opt = vim.opt

g.loaded_netrwPlugin = 1
opt.cursorcolumn = true
-- opt.shell = "fish"

-- vim.cmd([[ hi def IlluminatedWordText gui=underline guibg=#525252" ]])
-- vim.cmd([[ hi def IlluminatedWordRead gui=underline guibg=#525252" ]])
-- vim.cmd([[ hi def IlluminatedWordWrite gui=underline guibg=#525252" ]])

-- make zsh files recognized as sh for bash-ls & treesitter
vim.filetype.add({
  extension = {
    zsh = "sh",
    sh = "sh", -- force sh-files with zsh-shebang to still get sh as filetype
  },
  filename = {
    [".zshrc"] = "sh",
    [".zshenv"] = "sh",
  },
})
