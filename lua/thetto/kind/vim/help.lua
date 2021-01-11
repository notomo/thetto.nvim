local M = {}

M.action_open = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("help " .. item.value)
    vim.cmd("only")
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("tab help " .. item.value)
  end
end

M.action_vsplit_open = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("vertical help " .. item.value)
  end
end

M.default_action = "open"

return M
