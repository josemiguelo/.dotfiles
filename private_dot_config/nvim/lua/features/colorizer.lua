return {
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = {
    filetypes = {
      "*",
      "!sidekick_terminal",
      "!fugitive",
    },
  },
}
