local M = {}

M._load = function(self, path, cwd)
  if not self.filelib.readable(path) then
    return {}
  end

  local items = {}
  local row = 1
  local f = io.open(path, "r")
  local to_relative = self.pathlib.relative_modifier(cwd)
  for line in f:lines() do
    local target = vim.fn.matchstr(line, "\\v^\\zs\\S*\\ze:[^=]*$")
    if not (target == "" or target == ".PHONY" or target:find(":") ~= nil) then
      local path_row = ("%s:%d"):format(to_relative(path), row)
      local desc = ("%s %s"):format(path_row, target)
      table.insert(items, {
        desc = desc,
        value = target,
        path = path,
        row = row,
        column_offsets = {value = #path_row + 1},
      })
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
    items = vim.list_extend(items, M._load(self, p, opts.cwd))
  end
  return items
end

vim.cmd("highlight default link ThettoMakeTargetPath Comment")

M.highlight = function(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  for i, item in ipairs(items) do
    highlighter:add("ThettoMakeTargetPath", i - 1, 0, item.column_offsets.value - 1)
  end
end

M.kind_name = "make/target"

return M
