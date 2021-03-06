local M = {}

M.opts = {key = "PATH"}

function M.collect(self)
  local items = {}
  local paths = vim.split(os.getenv(self.opts.key), self.pathlib.env_separator, true)
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) ~= 0 then
      table.insert(items, {value = path, path = path})
    end
  end
  return items
end

M.kind_name = "file/directory"

return M
