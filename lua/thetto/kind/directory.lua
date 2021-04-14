local M = {}

function M.after(_)
end

function M.action_cd(_, items)
  for _, item in ipairs(items) do
    vim.cmd("lcd " .. item.path)
    M.after(item.path)
  end
end

function M.action_tab_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd("tabedit")
    vim.cmd("lcd " .. item.path)
    M.after(item.path)
  end
end

function M.action_vsplit_open(_, items)
  for _, item in ipairs(items) do
    vim.cmd("vsplit")
    vim.cmd("lcd " .. item.path)
    M.after(item.path)
  end
end

function M.action_enter(_, items)
  local item = items[1]
  if item == nil then
    return
  end
  vim.cmd("Thetto file/in_dir --cwd=" .. item.path)
end

M.action_open = M.action_cd
M.action_directory_open = M.action_open
M.action_directory_tab_open = M.action_tab_open
M.action_directory_enter = M.action_enter

M.default_action = "cd"

return M
