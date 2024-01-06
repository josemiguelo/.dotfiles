return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "html",
        "javascript",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "query",
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "🌲select around function" },
            ["if"] = { query = "@function.inner", desc = "🌲select inside function" },
            ["ac"] = { query = "@class.outer", desc = "🌲select around class" },
            ["ic"] = { query = "@class.inner", desc = "🌲select inside class" },
            ["al"] = { query = "@loop.outer", desc = "🌲select around loop" },
            ["il"] = { query = "@loop.inner", desc = "🌲select inside loop" },
            ["ab"] = { query = "@block.outer", desc = "🌲select around block" },
            ["ib"] = { query = "@block.inner", desc = "🌲select inside block" },
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["g+"] = { query = "@function.outer", desc = "🌲go to next function" },
            ["gc+"] = { query = "@class.outer", desc = "🌲go to next class" },
            ["gl+"] = { query = "@loop.outer", desc = "🌲go to next loop" },
            ["gb+"] = { query = "@block.outer", desc = "🌲go to next block" },
          },
          goto_previous_start = {
            ["g-"] = { query = "@function.outer", desc = "🌲go to previous function" },
            ["gc-"] = { query = "@class.outer", desc = "🌲go to previous class" },
            ["gl-"] = { query = "@loop.outer", desc = "🌲go to previous loop" },
            ["gb-"] = { query = "@block.outer", desc = "🌲go to previous block" },
          },
        },
        lsp_interop = {
          enable = true,
          border = "rounded",
          peek_definition_code = {
            ["gp"] = { query = "@function.outer", desc = "🌲peek function definition" },
            ["gcp"] = { query = "@class.outer", desc = "🌲peek class definition" },
          },
        },
      },
      playground = {
        enable = true,
        disable = {},
        updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
        persist_queries = false, -- Whether the query persists across vim sessions
        keybindings = {
          toggle_query_editor = "o",
          toggle_hl_groups = "i",
          toggle_injected_languages = "t",
          toggle_anonymous_nodes = "a",
          toggle_language_display = "I",
          focus_language = "f",
          unfocus_language = "F",
          update = "R",
          goto_node = "<cr>",
          show_help = "?",
        },
      },
      cmd = { "TSPlaygroundToggle" },
    },
  },
  { "nvim-treesitter/playground" },
}
