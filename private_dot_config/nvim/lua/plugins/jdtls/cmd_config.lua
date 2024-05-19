local home = os.getenv("HOME")
local java_bin_path = home .. "/.asdf/installs/java/adoptopenjdk-17.0.11+9/bin/java"
local workspace_path = home .. "/.local/share/nvim/jdtls-workspace/"
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = workspace_path .. project_name
local default_mason_path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/")
local root_patterns = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }

local expand_jars = function(expression)
  return vim.split(vim.fn.glob(expression), "\n")
end

local mason_package_path = function(package_name)
  return default_mason_path .. "packages/" .. package_name
end

local build_bundles = function()
  local bundles = {}

  local expanded_java_test_jars = expand_jars(mason_package_path("java-test") .. "/extension/server/*.jar")
  vim.list_extend(bundles, expanded_java_test_jars)

  local java_dap_jars = mason_package_path("java-debug-adapter")
    .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"

  vim.list_extend(bundles, expand_jars(java_dap_jars))

  return bundles
end

local os_config = "linux"
if vim.fn.has("mac") == 1 then
  os_config = "mac"
end

local function build_capabilities()
  local client_capabilities = vim.lsp.protocol.make_client_capabilities()
  client_capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }

  local capabilities = require("cmp_nvim_lsp").default_capabilities(client_capabilities)

  local extendedClientCapabilities = require("jdtls").extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  return capabilities, extendedClientCapabilities
end

local M = {}

M.build_jdtls_config = function()
  local capabilities, extendedClientCapabilities = build_capabilities()

  local cmd_config = {
    java_bin_path,
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xms1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-javaagent:" .. mason_package_path("jdtls") .. "/lombok.jar",
    "-jar",
    vim.fn.glob(mason_package_path("jdtls") .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
    "-configuration",
    mason_package_path("jdtls") .. "/config_" .. os_config,
    "-data",
    workspace_dir,
  }

  local settings_config = {
    java = {
      autobuild = { enabled = false },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      saveActions = {
        organizeImports = false,
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true,
      },
      eclipse = {
        downloadSources = true,
      },
      configuration = {
        updateBuildConfiguration = "interactive",
        runtimes = {
          {
            name = "JavaSE-17",
            path = home .. "/.asdf/installs/java/adoptopenjdk-17.0.11+9",
          },
          {
            name = "JavaSE-11",
            path = home .. "/.asdf/installs/java/adoptopenjdk-11.0.23+9",
          },
          {
            name = "JavaSE-1.8",
            path = home .. "/.asdf/installs/java/zulu-8.78.0.19",
          },
        },
      },
      maven = {
        downloadSources = true,
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        parameterNames = {
          enabled = "all", -- literals, all, none
        },
      },
      format = {
        enabled = true,
      },
      -- NOTE: We can set the formatter to use different styles
      -- format = {
      --   enabled = true,
      --   settings = {
      --     url = vim.fn.stdpath "config" .. "/lang-servers/intellij-java-google-style.xml",
      --     profile = "GoogleStyle",
      --   },
      -- },
    },
  }

  local handlers_config = {
    -- ["language/status"] = function(_error, _result)
    --   -- print(result)
    -- end,
    -- ["$/progress"] = function(_error, _result, _ctx)
    --   -- print(result)
    -- end,
  }

  return {
    cmd = cmd_config,
    root_dir = require("jdtls.setup").find_root(root_patterns),
    capabilities = capabilities,
    settings = settings_config,
    handlers = handlers_config,
    init_options = { bundles = build_bundles() },
    extendedClientCapabilities = extendedClientCapabilities,
  }
end

return M
