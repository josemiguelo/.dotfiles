return {
  {
    "yarospace/lua-console.nvim",
    lazy = true,
    opts = {},
    keys = { "`", "<Leader>`" },
  },
  {
    "jbyuki/one-small-step-for-vimkind",
    keys = {
      {
        "<leader>dD",
        function()
          require("osv").launch({ port = 8086 })
        end,
        desc = "Launch lua adapter",
      },
    },
  },
}
