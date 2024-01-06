local M = {}

M.set_keymaps = function(bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc, buffer = bufnr, noremap = true })
  end

  local wk = require("which-key")
  local keys = { mode = { "n", "v" }, ["<leader>cj"] = { name = "+Java" } }
  wk.register(keys)

  local jdtls = require("jdtls")
  map("n", "<leader>cjo", jdtls.organize_imports, "Organize Imports")
  map("n", "<leader>cjv", jdtls.extract_variable, "Extract Variable")
  map("n", "<leader>cjc", jdtls.extract_constant, "Extract Constant")
  map("n", "<leader>cjt", jdtls.test_nearest_method, "Test Nearest Method")
  map("n", "<leader>cjT", jdtls.test_class, "Test Class")
  map("n", "<leader>cju", "<cmd>JdtUpdateConfig<cr>", "Update Config")
  map("v", "<leader>cjv", "<esc><cmd>lua require('jdtls').extract_variable(true)<cr>", "Extract Variable")
  map("v", "<leader>cjc", "<esc><cmd>lua require('jdtls').extract_constant(true)<cr>", "Extract Constant")
  map("v", "<leader>cjm", "<esc><Cmd>lua require('jdtls').extract_method(true)<cr>", "Extract Method")
end

return M
