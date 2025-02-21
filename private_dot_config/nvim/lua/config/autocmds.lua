local jdt_utils = require("utils.jdtls")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "java" },
  callback = function()
    vim.o.tabstop = 4
    vim.o.shiftwidth = 4
  end,
})

vim.api.nvim_create_user_command("JdtInfo", function()
  jdt_utils.info()
end, { desc = "Confirms if the JDT server is active or not for the current project" })
