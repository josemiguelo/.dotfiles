return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "java" })
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "jdtls", "java-debug-adapter", "java-test", "google-java-format" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "mfussenegger/nvim-jdtls" },
    opts = {
      setup = {
        jdtls = function(_, _opts)
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "java",
            callback = function()
              if require("plugins.jdtls.skip_init").should_skip_server() then
                return
              end

              require("lazyvim.util").lsp.on_attach(function(client, bufnr)
                if client.name == "jdtls" then
                  -- client.server_capabilities.definitionProvider = true

                  local _, _ = pcall(vim.lsp.codelens.refresh)
                  -- jdtls.setup_dap({ hotcodereplace = "auto" })
                  -- require("jdtls.dap").setup_dap_main_class_configs()

                  vim.api.nvim_create_autocmd("BufWritePost", {
                    pattern = { "*.java" },
                    callback = function()
                      local _, _ = pcall(vim.lsp.codelens.refresh)
                    end,
                  })

                  require("plugins.jdtls.keymaps").set_keymaps(bufnr)

                  vim.o.tabstop = 4
                  vim.o.shiftwidth = 4
                end
              end)

              require("jdtls").start_or_attach(require("plugins.jdtls.cmd_config").build_jdtls_config())
            end,
          })
          return true
        end,
      },
    },
  },
}
