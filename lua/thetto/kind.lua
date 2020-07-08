local M = {}

M.options = {
  move_to_filter = {quit = false},
  move_to_list = {quit = false}
}

M.move_to_filter = function(_, state)
  vim.api.nvim_set_current_win(state.filter.window)
  vim.api.nvim_command("startinsert")
end

M.move_to_list = function(_, state)
  vim.api.nvim_set_current_win(state.list.window)
end

return M
