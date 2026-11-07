-- Loaded by mason-kotlin-lsp.sh under `nvim --headless --clean`, with only
-- mason.nvim (lazy's clone) on the runtimepath and Mason's default install
-- root, the same one LazyVim's Mason uses. One package
-- ($LOADOUT_MASON_PACKAGE), one mode ($LOADOUT_MASON_MODE), lines written to
-- $LOADOUT_MASON_OUT ending with a lone `__LOADOUT_NVIM_OK__` sentinel; the
-- shell reads its absence (crash, timeout, Lua error) as a failure. A
-- `__LOADOUT_NVIM_ERR__ <reason>` line carries the reason when there is one.
--
--   versions  "<installed or -> <latest>": the latest from Mason's registry,
--             refreshed when its cache is older than a day.
--   install   install the registry's latest (an update when installed).
local OK = "__LOADOUT_NVIM_OK__"
local ERR = "__LOADOUT_NVIM_ERR__"
local out_path = vim.env.LOADOUT_MASON_OUT
local name = vim.env.LOADOUT_MASON_PACKAGE
local mode = vim.env.LOADOUT_MASON_MODE or "versions"

-- "kotlin-lsp/v263.7084.0" (the release tag Mason versions by) -> "263.7084.0".
local function bare(version)
  return version and (version:gsub("^.*/", ""):gsub("^v", ""))
end

local function finish(lines, err)
  local fd = io.open(out_path, "w")
  if not fd then return end
  if err then
    fd:write(ERR .. " " .. tostring(err) .. "\n")
  else
    fd:write(table.concat(lines, "\n") .. (#lines > 0 and "\n" or "") .. OK .. "\n")
  end
  fd:close()
  vim.schedule(function() vim.cmd("qa!") end)
end

local ok, err = pcall(function()
  require("mason").setup()
  local registry = require("mason-registry")
  registry.refresh(function(refreshed)
    local got, pkg = pcall(registry.get_package, name)
    if not refreshed or not got then
      return finish(nil, not refreshed and "Mason's registry didn't refresh" or ("no Mason package " .. name))
    end
    if mode == "versions" then
      return finish({ (bare(pkg:get_installed_version()) or "-") .. " " .. bare(pkg:get_latest_version()) })
    end
    pkg:install({}, function(success, result)
      if success then
        finish({ name .. " " .. tostring(bare(pkg:get_installed_version())) })
      else
        finish(nil, tostring(result))
      end
    end)
  end)
end)
if not ok then finish(nil, err) end
