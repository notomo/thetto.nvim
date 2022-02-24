local pathlib = require("thetto.lib.path")

local Modifier = {}
Modifier.__index = Modifier

function Modifier.new(f, name)
  vim.validate({ f = { f, "function" }, name = { name, "string", true } })
  local tbl = { f = f, name = name }
  return setmetatable(tbl, Modifier)
end

local M = {}
M.__index = M

function M.new(cwd)
  vim.validate({ cwd = { cwd, "string" } })
  local tbl = {
    _modifiers = {
      relative = function(value)
        return pathlib.to_relative(value, cwd)
      end,
    },
  }
  return setmetatable(tbl, M)
end

function M.create(self, name)
  vim.validate({ name = { name, "string", true } })
  if not name then
    return Modifier.new(function(value)
      return value
    end)
  end

  local f = self._modifiers[name]
  if not f then
    return nil, "not found filter modifier: " .. name
  end
  return Modifier.new(f, name)
end

return M
