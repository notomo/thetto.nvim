local M = {}

function M.action_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd("help " .. item.value)
    vim.cmd("only")
  end
end

function M.action_tab_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd("tab help " .. item.value)
  end
end

function M.action_vsplit_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd("vertical help " .. item.value)
  end
end

M.default_action = "open"

return M
