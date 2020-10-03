local M = {}

M.key = "PATH"

M.collect = function(self)
  local items = {}
  local paths = vim.split(os.getenv(M.key), self.pathlib.env_separator, true)
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) ~= 0 then
      table.insert(items, {value = path, path = path})
    end
  end
  return items
end

M.kind_name = "directory"

return M
