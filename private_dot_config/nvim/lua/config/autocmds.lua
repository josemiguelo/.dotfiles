local jdt_utils = require("utils.jdtls")

pcall(require, "private.autocmds")

vim.api.nvim_create_user_command("JdtInfo", function()
  jdt_utils.info()
end, { desc = "Confirms if the JDT server is active or not for the current project" })
