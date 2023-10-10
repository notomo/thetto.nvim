local modulelib = require("thetto.vendor.misclib.module")
local vim = vim

local Sorter = {}

function Sorter.new(name, reversed, key)
  vim.validate({
    name = { name, "string" },
    reversed = { reversed, "boolean" },
    key = { key, "string", true },
  })

  local origin = modulelib.find("thetto.handler.sorter." .. name)
  if origin == nil then
    return nil, "not found sorter: " .. name
  end

  key = key or "value"
  local tbl = {
    reversed = reversed,
    key = key,
    keys = vim.split(key, ".", { plain = true }),
    short_name = name,
    _origin = origin,
  }
  return setmetatable(tbl, Sorter), nil
end

function Sorter.parse(name)
  local reversed = false
  if vim.startswith(name, "-") then
    reversed = true
    name = name:sub(2)
  end

  local args = vim.split(name, ":", { plain = true })
  name = args[1]
  local key = args[2]

  return Sorter.new(name, reversed, key)
end

function Sorter.reverse(self)
  return Sorter.new(self.short_name, not self.reversed, self.key)
end

function Sorter._name(self)
  local name
  if self.key ~= "value" then
    name = ("%s:%s"):format(self.short_name, self.key)
  else
    name = self.short_name
  end
  if self.reversed then
    return "-" .. name
  end
  return name
end

function Sorter.__index(self, k)
  if k == "name" then
    return Sorter._name(self)
  end
  return rawget(Sorter, k) or self._origin[k]
end

local pathlib = require("thetto.lib.path")

function Sorter.all()
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/handler/sorter/**/*.lua", true)
  local all = {}
  for _, path in ipairs(paths) do
    local sorter_file = vim.split(pathlib.adjust_sep(path), "lua/thetto/handler/sorter/", { plain = true })[2]
    local name = sorter_file:sub(1, #sorter_file - 4)
    local ignored = vim.startswith(vim.fs.basename(sorter_file), "_")
    if not ignored then
      local sorter_info = {
        name = name,
        path = path,
      }
      table.insert(all, sorter_info)
    end
  end
  return all
end

return Sorter
