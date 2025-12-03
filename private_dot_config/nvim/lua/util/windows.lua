local M = {}

function M.get_window_by_ft(ft)
  local win_ret = nil

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
    if filetype == ft then
      win_ret = win
    end
  end

  return win_ret
end

return M
