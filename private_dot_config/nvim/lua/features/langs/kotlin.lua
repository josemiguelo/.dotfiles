return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "kotlin" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = { kotlin_lsp = { enabled = false } },
    },
  },

  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = {
      "mason-lspconfig.nvim",
      "oil.nvim",
      "trouble.nvim",
      {
        "mason.nvim",
        opts = { ensure_installed = { "kotlin-lsp" } },
      },
    },
    config = function()
      require("kotlin").setup({
        root_markers = {
          "settings.gradle",
          "settings.gradle.kts",
          "build.xml",
          "pom.xml",
          "build.gradle",
          "build.gradle.kts",
        },

        jdk_for_symbol_resolution = vim.env.HOME .. "/.asdf/installs/java/adoptopenjdk-21.0.6+7.0.LTS",
      })
    end,
  },
}
