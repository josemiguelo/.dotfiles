local g = vim.g
local opt = vim.opt
local ft = vim.filetype

opt.cursorcolumn = true

-- make zsh files recognized as sh for bash-ls & treesitter
ft.add({
  extension = {
    zsh = "sh",
    sh = "sh", -- force sh-files with zsh-shebang to still get sh as filetype
  },
  filename = {
    [".zshrc"] = "sh",
    [".zshenv"] = "sh",
  },
})

-- autostart jdtls on java projects
g.autostartjdtls = true
