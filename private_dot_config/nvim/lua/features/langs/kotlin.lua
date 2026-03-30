return {
  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    opts = {
      root_markers = {
        "build.gradle",
        "build.gradle.kts",
        "pom.xml",
        "mvnw",
        "gradlew",
        ".git",
        "mvnw",
        "settings.gradle",
      },
    },
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = { ensure_installed = { "kotlin-lsp" } },
      },
      {
        "neovim/nvim-lspconfig",
        opts = {
          setup = {
            kotlin_language_server = function()
              return true
            end,
          },
        },
      },
      "oil.nvim",
      "trouble.nvim",
    },
  },
}
