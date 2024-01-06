return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()

      keys[#keys + 1] = { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "Goto Definition", has = "definition" }
      keys[#keys + 1] = { "gI", "<cmd>Telescope lsp_implementations<cr>", desc = "Goto Implementation" }
      keys[#keys + 1] = { "gy", "<cmd>Telescope lsp_type_definitions<cr>", desc = "Goto T[y]pe Definition" }
      keys[#keys + 1] = {
        "gr",
        function()
          require("trouble").open("lsp_references")
        end,
        desc = "References",
      }
    end,
  },
}
