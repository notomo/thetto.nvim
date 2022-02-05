local M = {}

function M.action_open(self, items)
  for _, item in ipairs(items) do
    self:_open(item, "", "action_open")
    vim.cmd("only")
  end
end

function M.action_tab_open(self, items)
  for _, item in ipairs(items) do
    self:_open(item, "tab", "action_tab_open")
  end
end

function M.action_vsplit_open(self, items)
  for _, item in ipairs(items) do
    self:_open(item, "vertical", "action_vsplit_open")
  end
end

local file_kind = require("thetto.handler.kind.file")

function M._open(self, item, help_prefix, edit_action)
  local ok = pcall(vim.cmd, ("%s help %s"):format(help_prefix, item.value))
  if ok then
    return
  end
  file_kind[edit_action](self, { item })
  vim.cmd([[nohlsearch]])
  vim.bo.buftype = "help"
  vim.bo.modifiable = false
end

M.default_action = "open"

return require("thetto.core.kind").extend(M, "file")
