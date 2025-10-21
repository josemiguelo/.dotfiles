return {
  "carbon-steel/detour.nvim",
  config = function()
    require("detour").setup()

    vim.keymap.set("n", "<c-w><enter>", ":Detour<cr>")
    vim.keymap.set("n", "<c-w>.", ":DetourCurrentWindow<cr>")

    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        local detour_moves = require("detour.movements")
        vim.keymap.set({ "n", "t" }, "<C-j>", detour_moves.DetourWinCmdJ)
        vim.keymap.set({ "n", "t" }, "<C-w>j", detour_moves.DetourWinCmdJ)
        vim.keymap.set({ "n", "t" }, "<C-w><C-j>", detour_moves.DetourWinCmdJ)

        vim.keymap.set({ "n", "t" }, "<C-h>", detour_moves.DetourWinCmdH)
        vim.keymap.set({ "n", "t" }, "<C-w>h", detour_moves.DetourWinCmdH)
        vim.keymap.set({ "n", "t" }, "<C-w><C-h>", detour_moves.DetourWinCmdH)

        vim.keymap.set({ "n", "t" }, "<C-k>", detour_moves.DetourWinCmdK)
        vim.keymap.set({ "n", "t" }, "<C-w>k", detour_moves.DetourWinCmdK)
        vim.keymap.set({ "n", "t" }, "<C-w><C-k>", detour_moves.DetourWinCmdK)

        vim.keymap.set({ "n", "t" }, "<C-l>", detour_moves.DetourWinCmdL)
        vim.keymap.set({ "n", "t" }, "<C-w>l", detour_moves.DetourWinCmdL)
        vim.keymap.set({ "n", "t" }, "<C-w><C-l>", detour_moves.DetourWinCmdL)

        vim.keymap.set({ "n", "t" }, "<C-w>w", detour_moves.DetourWinCmdW)
        vim.keymap.set({ "n", "t" }, "<C-w><C-w>", detour_moves.DetourWinCmdW)
      end,
    })
  end,
}
