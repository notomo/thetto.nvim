local M = {}

function M.action_open(_, items)
  for _, item in ipairs(items) do
    M._open(item, "", "action_open")
    vim.cmd("only")
  end
end

function M.action_tab_open(_, items)
  for _, item in ipairs(items) do
    M._open(item, "tab", "action_tab_open")
  end
end

function M.action_vsplit_open(_, items)
  for _, item in ipairs(items) do
    M._open(item, "vertical", "action_vsplit_open")
  end
end

local file_kind = require("thetto.handler.kind.file")

function M._open(item, help_prefix, edit_action)
  local ok = pcall(vim.cmd, ("%s help %s"):format(help_prefix, item.value))
  if ok then
    return
  end
  file_kind[edit_action](file_kind, { item })
  vim.cmd([[nohlsearch]])
  vim.bo.buftype = "help"
  vim.bo.modifiable = false
end

M.default_action = "open"

return require("thetto.core.kind").extend(M, "file")
