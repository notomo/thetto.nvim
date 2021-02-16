local M = {}

M.action_open = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("Man " .. item.value)
    vim.cmd("only")
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("tab Man " .. item.value)
  end
end

M.action_vsplit_open = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("vertical Man " .. item.value)
  end
end

M.action_split_open = function(_, items)
  for _, item in ipairs(items) do
    vim.cmd("Man " .. item.value)
  end
end

return M
