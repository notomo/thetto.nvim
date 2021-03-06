local M = {}

function M.action_open(self, items)
  for _, item in ipairs(items) do
    self.filelib.create_if_need(item.path)
    vim.cmd("edit " .. self.filelib.escape(item.path))
  end
end

function M.action_tab_open(self, items)
  for _, item in ipairs(items) do
    self.filelib.create_if_need(item.path)
    vim.cmd("tabedit " .. self.filelib.escape(item.path))
  end
end

function M.action_vsplit_open(self, items)
  for _, item in ipairs(items) do
    self.filelib.create_if_need(item.path)
    vim.cmd("vsplit" .. self.filelib.escape(item.path))
  end
end

M.default_action = "open"

return M
