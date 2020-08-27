local M = {}

M.action_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("buffer " .. item.bufnr)
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit")
    vim.api.nvim_command("buffer " .. item.bufnr)
  end
end

M.action_vsplit_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("buffer " .. item.bufnr)
  end
end

M.action_preview = function(_, items, ctx)
  local item = items[1]
  if item == nil or not vim.api.nvim_buf_is_loaded(item.bufnr) then
    return
  end
  ctx.ui:open_preview({bufnr = item.bufnr})
end

M.default_action = "open"

return M
