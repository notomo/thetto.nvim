local filelib = require("thetto.lib.file")

local M = {}

function M._load(path)
  if not filelib.readable(path) then
    return {}
  end

  local f = io.open(path, "r")
  assert(f, "failed to open: " .. path)
  local json = f:read("*a")
  f:close()
  local content = vim.json.decode(json)

  local lines = vim.split(json, "\n", { plain = true })
  local rows = {}
  for row, line in ipairs(lines) do
    local k, v = line:match([["([^"]+)": "([^"]+)"]])
    if k and v then
      rows[k .. v] = row
    end
  end

  local items = {}
  for k, v in pairs(content.scripts) do
    table.insert(items, {
      value = k,
      path = path,
      row = rows[k .. v],
    })
  end

  return items
end

function M.collect(source_ctx)
  local path = vim.fs.joinpath(source_ctx.cwd, "package.json")
  return M._load(path)
end

M.kind_name = "cmd/npm/script"

return M
