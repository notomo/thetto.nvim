local M = {}

function M._load(self, path)
  if not self.filelib.readable(path) then
    return {}
  end

  local f = io.open(path, "r")
  local json = f:read("*a")
  f:close()
  local content = vim.json.decode(json)

  local items = {}
  for key in pairs(content.scripts) do
    table.insert(items, {value = key, path = path})
  end

  return items
end

function M.collect(self, opts)
  local path = opts.cwd .. "/package.json"
  return M._load(self, path)
end

M.kind_name = "cmd/npm/script"

return M
