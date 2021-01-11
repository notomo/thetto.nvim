local M = {}

M.opts = {cmd = "messages"}

M.collect = function(self)
  local items = {}
  local outputs = vim.api.nvim_exec(self.opts.cmd, true)
  for line in vim.gsplit(outputs, "\n", true) do
    table.insert(items, {value = line})
  end
  return items
end

M.kind_name = "word"

return M
