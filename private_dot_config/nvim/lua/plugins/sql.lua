return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  { -- optional saghen/blink.cmp completion source
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources.default = opts.sources.default or {}
      vim.list_extend(opts.sources.default, { "dadbod" })

      opts.sources.providers = vim.tbl_extend("keep", {
        dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
      }, opts.sources.providers or {})
    end,
  },
}
