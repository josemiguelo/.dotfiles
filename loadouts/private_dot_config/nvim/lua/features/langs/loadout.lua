return {
  {
    -- loadout's own language server for its HCL manifests: what compile
    -- would refuse, as you type, and completion of program./script./
    -- profile./installer./local. names declared anywhere in the repo
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        loadout = {
          -- in loadout since 4.1.0, which loadout.hcl's min_tool_version
          -- guarantees on every machine that applies this
          cmd = { "loadout", "lsp" },
          filetypes = { "hcl" },
          root_markers = { "loadout.hcl" },
          -- other HCL (terraform's, packer's) is none of its business
          workspace_required = true,
        },
      },
    },
  },
}
