local M = {}

M.action_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_win_set_cursor(0, {item.row, 0})
  end
end

M.action_tab_open = function(_, items)
  local bufnr = vim.api.nvim_get_current_buf()
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit")
    vim.api.nvim_command("buffer " .. bufnr)
    vim.api.nvim_win_set_cursor(0, {item.row, 0})
  end
end

M.action_vsplit_open = function(_, items)
  local bufnr = vim.api.nvim_get_current_buf()
  for _, item in ipairs(items) do
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("buffer " .. bufnr)
    vim.api.nvim_win_set_cursor(0, {item.row, 0})
  end
end

M.action_preview = function(_, items, ctx)
  local item = items[1]
  if item == nil then
    return
  end
  ctx.ui:open_preview(item, {bufnr = item.bufnr, row = item.row})
end

M.default_action = "open"

return M
