local vim = vim

local M = {}

function M.collect(self)
  local items = {}
  local paths = self.listlib.unique(vim.api.nvim_get_runtime_file("doc/tags", true))
  for _, path in ipairs(paths) do
    local f = io.open(path, "r")
    for line in f:lines() do
      local tag = vim.split(line, "\t")[1]
      table.insert(items, {value = tag})
    end
    f:close()
  end
  return items
end

M.kind_name = "vim/help"

return M
