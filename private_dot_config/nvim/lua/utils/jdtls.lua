local M = {}

function M.enabled()
  return vim.g.autostartjdtls == nil or vim.g.autostartjdtls
end

function M.toggle()
  vim.g.autostartjdtls = not M.enabled()
  M.info()
end

function M.info()
  LazyVim[M.enabled() and "info" or "warn"](
    { ("**%s**"):format((M.enabled() and "enabled" or "disabled") .. " on the whole project") },
    { title = "Jdtls" }
  )
end

return M
