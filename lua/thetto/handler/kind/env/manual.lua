local M = {}

function M.action_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd.Man(item.value)
    vim.cmd.only()
  end
end

function M.action_tab_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd.Man({ mods = { tab = 0 }, args = { item.value } })
  end
end

function M.action_vsplit_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd.Man({ mods = { vertical = true }, args = { item.value } })
  end
end

function M.action_split_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd.Man(item.value)
  end
end

return M
