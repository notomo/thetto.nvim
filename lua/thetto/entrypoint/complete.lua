local kinds = require("thetto/core/kind")
local sources = require("thetto/core/source")
local repository = require("thetto/core/repository")

local M = {}

M.action = function(_, _, _)
  local ctx, err = repository.get_from_path()
  if err ~= nil then
    return ""
  end

  local item = ctx.ui:selected_items()[1]
  if item == nil then
    return ""
  end

  local kind_name = item.kind_name or ctx.collector.source.kind_name
  local names = kinds.actions(kind_name, ctx.collector.source.name)
  return table.concat(names, "\n")
end

M.source = function(_, _, _)
  local names = sources.names()
  return table.concat(names, "\n")
end

return M
