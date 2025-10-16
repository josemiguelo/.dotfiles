--[[
List mode: By default, show tabs as ">", trailing spaces as "-", and
non-breakable space characters as "+". Useful to see the difference
between tabs and spaces and for trailing blanks. Further changed by
the 'listchars' option.
--]]
vim.opt.list = true
vim.opt.listchars = {
  eol = "⤶",
  space = "·",
  tab = "▸ ",
  trail = "•",
  extends = "»",
  precedes = "«",
  nbsp = "␣",
  lead = "·",
  leadmultispace = "·",
}

return {}
