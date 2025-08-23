local filelib = require("thetto.lib.file")

local M = {}

function M.action_open(items)
  for _, item in ipairs(items) do
    filelib.create_if_need(item.path)
    vim.cmd.edit({ args = { item.path }, magic = { file = false } })
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    filelib.create_if_need(item.path)
    vim.cmd.tabedit({ args = { item.path }, magic = { file = false } })
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    filelib.create_if_need(item.path)
    vim.cmd.vsplit({ args = { item.path }, magic = { file = false } })
  end
end

M.default_action = "open"

return M
