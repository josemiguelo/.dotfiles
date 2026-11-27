return {
  "L3MON4D3/LuaSnip",
  opts = function()
    local ls = require("luasnip")
    -- Extend 'lua' to also use 'luadoc' snippets
    ls.filetype_extend("lua", { "luadoc" })
  end,
}
