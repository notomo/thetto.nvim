local M = {}

M.action_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("edit " .. item.path)
    if item.row ~= nil then
      vim.api.nvim_win_set_cursor(0, {item.row, 0})
    end
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit " .. item.path)
    if item.row ~= nil then
      vim.api.nvim_win_set_cursor(0, {item.row, 0})
    end
  end
end

M.action_vsplit_open = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("edit " .. item.path)
    if item.row ~= nil then
      vim.api.nvim_win_set_cursor(0, {item.row, 0})
    end
  end
end

local directory_kind = require("thetto/kind/directory")

local to_dirs = function(items)
  local dirs = {}
  for _, item in ipairs(items) do
    item.path = vim.fn.fnamemodify(item.path, ":h")
    item.value = item.path
    table.insert(dirs, item)
  end
  return dirs
end

M.action_directory_open = function(self, items)
  directory_kind.action_open(self, to_dirs(items))
end

M.action_directory_tab_open = function(self, items)
  directory_kind.action_tab_open(self, to_dirs(items))
end

M.default_action = "open"

return M
