local M = {}

M.action_open = function(self, items)
  for _, item in ipairs(items) do
    self.filelib.create_if_need(item.path)
    vim.api.nvim_command("edit " .. item.path)
  end
end

M.action_tab_open = function(self, items)
  for _, item in ipairs(items) do
    self.filelib.create_if_need(item.path)
    vim.api.nvim_command("tabedit " .. item.path)
  end
end

M.action_vsplit_open = function(self, items)
  for _, item in ipairs(items) do
    self.filelib.create_if_need(item.path)
    vim.api.nvim_command("vsplit" .. item.path)
  end
end

M.default_action = "open"

return M