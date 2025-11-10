return {
  -- make sure jdtls is installed and available via mason.nvim
  {
    "mfussenegger/nvim-jdtls",
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = { ensure_installed = { "jdtls" } },
      },
    },
  },

  -- for displaying the project's java dependencies in a tree view
  {
    "mfussenegger/nvim-jdtls",
    dependencies = {
      {
        "josemiguelo/java-deps.nvim",
        branch = "fix-error-opening-picker",
        dependencies = {
          "folke/snacks.nvim",
          {
            "mason-org/mason.nvim",
            opts = { ensure_installed = { "vscode-java-dependency" } },
          },
        },
        config = function() end,
      },
    },
    opts = {
      jdtls = function(config)
        config.init_options = config.init_options or {}
        config.init_options.bundles = config.init_options.bundles or {}

        if LazyVim.has("mason.nvim") then
          if require("mason-registry").is_installed("vscode-java-dependency") and LazyVim.has("java-deps.nvim") then
            config.init_options.bundles = vim.list_extend(
              vim.deepcopy(config.init_options.bundles),
              vim.fn.glob("$MASON/share/vscode-java-dependency/com.microsoft.jdtls.ext.core-*.jar", false, true)
            )
          end
        end
      end,
    },
  },

  -- disable lsp's formatting capabilities since we want to use google-java-format instead
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      jdtls = function(config)
        config.settings = config.settings or {}
        config.settings.java = config.settings.java or {}
        config.settings.java.format = { enabled = false }
      end,
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        java = { "google-java-format" },
      },
      formatters = {
        ["google-java-format"] = {
          append_args = { "--aosp" },
        },
      },
    },
  },

  -- use custom port for java debug adapter
  {
    "mfussenegger/nvim-dap",
    opts = function()
      require("dap").configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Debug (Attach) - Remote",
          hostName = "127.0.0.1",
          port = 8000,
        },
      }
    end,
  },
}
