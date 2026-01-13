return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- List of languages you want to omit
      local to_omit = {
        "jsonc", -- there's an error downloading since it's hosted on gitlab
      }

      if type(opts.ensure_installed) == "table" then
        opts.ensure_installed = vim.tbl_filter(function(lang)
          return not vim.tbl_contains(to_omit, lang)
        end, opts.ensure_installed)
      end
    end,
  },
}
