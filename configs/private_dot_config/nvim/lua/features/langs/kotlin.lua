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
      {
        "mason-lspconfig.nvim",
        opts = { automatic_enable = { exclude = { "kotlin_lsp" } } },
      },
      "oil.nvim",
      "trouble.nvim",
      {
        "mason.nvim",
        -- kotlin.nvim checks for Mason, but Mason doesn't install kotlin-lsp:
        -- its download 404s (mason-registry#17523). Once that's fixed, put
        -- `ensure_installed = { "kotlin-lsp" }` back here and drop loadout's.
        -- opts = { ensure_installed = { "kotlin-lsp" } },
      },
    },
    config = function()
      -- Mason can't download kotlin-lsp (mason-registry#17523), so loadout
      -- installs it here (.loadout/install-kotlin-lsp.sh). kotlin.nvim
      -- prefers a Mason install when one exists.
      local kotlin_lsp_dir = vim.env.HOME .. "/.local/share/kotlin-lsp/current"
      if not vim.env.KOTLIN_LSP_DIR and vim.fn.isdirectory(kotlin_lsp_dir) == 1 then
        vim.env.KOTLIN_LSP_DIR = kotlin_lsp_dir
      end

      require("kotlin").setup({
        root_markers = {
          "settings.gradle",
          "settings.gradle.kts",
          "build.xml",
          "pom.xml",
          "build.gradle",
          "build.gradle.kts",
        },

        jdk_for_symbol_resolution = vim.env.HOME .. "/.local/share/mise/installs/java/temurin-21.0.6+7.0.LTS",
      })
    end,
  },
}
