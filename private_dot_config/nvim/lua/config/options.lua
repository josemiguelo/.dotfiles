if vim.env.TMUX ~= nil then
  -- Force Neovim to send the undercurl sequences even if the terminfo is missing them
  vim.cmd([[let &t_Cs = "\e[4:3m"]])
  vim.cmd([[let &t_Ce = "\e[4:0m"]])
end
