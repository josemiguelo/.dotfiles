return {
  {
    -- Fork of folke/flash.nvim with the nvim 0.13 fix from PR #492.
    -- Neovim moved the search globals flash reads over FFI into a SearchState
    -- struct (neovim/neovim#39485), which breaks `f`/`t` with:
    --   dlsym(RTLD_DEFAULT, search_match_lines): symbol not found
    -- TODO: go back to "folke/flash.nvim" once folke/flash.nvim#492 is merged.
    "onion108/flash.nvim",
    commit = "25ce9b72a8be5a8458c8983c8af766c8fbbc2012",
    keys = {
      -- Simulate nvim-treesitter incremental selection
      {
        "<c-n>",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter({
            actions = {
              ["<c-n>"] = "next",
              ["<c-p>"] = "prev",
            },
            -- don't show the labels, just highlight
            label = {
              after = false,
              before = false,
            },
          })
        end,
        desc = "Treesitter Incremental Selection",
      },
    },
  },
}
