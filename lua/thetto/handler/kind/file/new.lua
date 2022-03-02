local filelib = require("thetto.lib.file")

local M = {}

function M.action_open(_, items)
  for _, item in ipairs(items) do
    filelib.create_if_need(item.path)
    vim.cmd("edit " .. filelib.escape(item.path))
  end
end

function M.action_tab_open(_, items)
  for _, item in ipairs(items) do
    filelib.create_if_need(item.path)
    vim.cmd("tabedit " .. filelib.escape(item.path))
  end
end

function M.action_vsplit_open(_, items)
  for _, item in ipairs(items) do
    filelib.create_if_need(item.path)
    vim.cmd("vsplit" .. filelib.escape(item.path))
  end
end

M.default_action = "open"

return M
