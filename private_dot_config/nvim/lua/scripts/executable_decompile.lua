#!nvim -l

local files = require("utils.files")
local strings = require("utils.strings")

local function sync_system_cmd(notif_msg, err_msg, cmd, opts)
  local function handle_data(err, data)
    if not strings.string_is_empty(err) then
      vim.print(err)
    end
    if not strings.string_is_empty(data) then
      vim.print(data)
    end
  end

  opts = vim.tbl_deep_extend("force", {
    text = true,
    stdout = handle_data,
    stderr = handle_data,
  }, opts or {})

  vim.notify(notif_msg)
  local job = vim.system(cmd, opts):wait()

  if job.code ~= 0 then
    vim.notify(err_msg)
    os.exit(1, true)
  end
end

local jar_full_path = _G.arg[1]
if strings.string_is_empty(jar_full_path) then
  vim.notify("jar name was not passed\n")
  os.exit(1, true)
end

if not files.is_file(jar_full_path) then
  vim.notify("jar " .. jar_full_path .. " does not exist\n")
  os.exit(1, true)
end

local decompiler = vim.fn.glob("~/jars/java-decompiler-engine-232.8660.185.jar")
if not files.is_file(decompiler) then
  vim.notify("decompiler " .. decompiler .. " not found\n")
  os.exit(1, true)
end

local decompiled_jars_dir = vim.fn.glob("~/decompiled_jars")
if not files.is_directory(decompiled_jars_dir) then
  vim.notify("directory " .. decompiled_jars_dir .. " not found\n")
  os.exit(1, true)
end

local jar_name = vim.fs.basename(jar_full_path)
local decompiled_jar_path = vim.fs.joinpath(decompiled_jars_dir, jar_name)
if files.is_file(decompiled_jar_path) then
  vim.notify("decompiled jar " .. jar_name .. " already exists at " .. decompiled_jar_path)
  os.exit(1, true)
end

local target_path = string.gsub(jar_name, ".jar", "")
local target_decompiled_jar_path = vim.fs.joinpath(decompiled_jars_dir, target_path)
if files.is_directory(target_decompiled_jar_path) then
  vim.notify("target directory " .. target_decompiled_jar_path .. " already exists ")
  os.exit(1, true)
end

sync_system_cmd(
  "decompiling " .. jar_full_path .. " into " .. decompiled_jar_path,
  "error when decompiling\n",
  { "java", "-jar", decompiler, jar_full_path, decompiled_jars_dir }
)

sync_system_cmd(
  "unzipping " .. decompiled_jar_path .. " into " .. target_decompiled_jar_path,
  "error when unzipping\n",
  { "unzip", decompiled_jar_path, "-d", target_decompiled_jar_path },
  { cwd = decompiled_jars_dir }
)

sync_system_cmd(
  "removing " .. decompiled_jar_path,
  "error when cleaning jar file\n",
  { "rm", decompiled_jar_path },
  { cwd = decompiled_jars_dir }
)
