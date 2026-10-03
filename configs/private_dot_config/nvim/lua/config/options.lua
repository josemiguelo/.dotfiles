if vim.env.TMUX ~= nil then
  -- Force Neovim to send the undercurl sequences even if the terminfo is missing them
  vim.cmd([[let &t_Cs = "\e[4:3m"]])
  vim.cmd([[let &t_Ce = "\e[4:0m"]])
end

vim.opt.colorcolumn = "120"

-- Clipboard over SSH + tmux: write-only sync, yanks only.
-- * "+" writes go to the tmux buffer and, via `load-buffer -w`, to the local
--   terminal's clipboard (OSC 52). Reads only come from the tmux buffer, so nvim
--   never asks the terminal for the local clipboard (no OSC 52 read).
-- * `clipboard` stays empty (LazyVim's SSH default) so deletes don't clobber the
--   clipboard; plain yanks are mirrored to "+" below. Use "+p to paste text
--   yanked in another nvim instance.
if vim.env.TMUX then
  local copy = { "tmux", "load-buffer", "-w", "-" }
  local paste = { "tmux", "save-buffer", "-" }
  vim.g.clipboard = {
    name = "tmux-write-only",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = true,
  }
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_to_clipboard", { clear = true }),
  callback = function()
    local ev = vim.v.event
    if ev.operator == "y" and ev.regname == "" then
      vim.fn.setreg("+", ev.regcontents, ev.regtype)
    end
  end,
})
