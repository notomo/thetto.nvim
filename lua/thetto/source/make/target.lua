local M = {}

M._load = function(self, path)
  if not self.filelib.readable(path) then
    return {}
  end

  local items = {}
  local row = 1
  local f = io.open(path, "r")
  for line in f:lines() do
    local target = vim.fn.matchstr(line, "\\v^\\zs\\S*\\ze:[^=]*$")
    if not (target == "" or target == ".PHONY" or target:find(":") ~= nil) then
      table.insert(items, {value = target, path = path, row = row})
    end
    row = row + 1
  end
  f:close()

  return items
end

M.collect = function(self, opts)
  local path = opts.cwd .. "/Makefile"
  local dir_path = vim.fn.fnamemodify(path, ":h")
  local paths = vim.fn.glob(dir_path .. "/*.mk", false, true)

  local items = {}
  for _, p in ipairs(vim.list_extend({path}, paths)) do
    items = vim.list_extend(items, M._load(self, p))
  end
  return items
end

M.kind_name = "make/target"

return M
