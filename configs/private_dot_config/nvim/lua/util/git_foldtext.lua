-- foldtext for commit buffers (Gclog, Flogsplitcommit, features/git.lua): a closed
-- file reads like a line of the status window, its git status letter and its path
-- in the status window's colors; a closed hunk keeps its @@ line, in diffLine
local M = {}

-- what git's --name-status calls the file, from its diff header
local headers = {
  { "^new file mode", "A" },
  { "^deleted file mode", "D" },
  { "^rename from", "R" },
  { "^copy from", "C" },
}

local function unquote(path)
  return path:sub(1, 1) == '"' and vim.fn["fugitive#Unquote"](path) or path
end

local function file_line(lines)
  local letter, path = "M", nil
  for _, line in ipairs(lines) do
    if line:match("^@@") then
      break
    end
    for _, header in ipairs(headers) do
      if line:match(header[1]) then
        letter = header[2]
      end
    end
    -- the new name, or the old one for a deleted file (its +++ is /dev/null)
    path = line:match("^rename to (.*)")
      or line:match("^copy to (.*)")
      or line:match('^%+%+%+ ("?)[abciow12]/') and line:sub(5)
      or (path == nil and line:match('^%-%-%- ("?)[abciow12]/') and line:sub(5))
      or path
  end
  if path then
    path = unquote(path):gsub("^[abciow12]/", "", 1)
  else
    -- no ---/+++ lines (a pure rename or mode change): take the diff line's new name
    path = unquote(lines[1]:match("^diff %-%-git .- (.*)$") or ""):gsub("^[abciow12]/", "", 1)
  end
  return {
    { letter, "fugitiveStagedModifier" },
    { " " },
    { path, "fugitiveStagedSection" },
  }
end

function M.foldtext()
  local first = vim.fn.getline(vim.v.foldstart)
  if first:match("^diff %-%-git ") then
    return file_line(vim.fn.getline(vim.v.foldstart, vim.v.foldend))
  elseif first:match("^@@") then
    return { { first, "diffLine" } }
  end
  return vim.fn["fugitive#Foldtext"]()
end

return M
