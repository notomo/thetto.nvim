local kinds = require("thetto/core/kind")
local sources = require("thetto/core/source")
local repository = require("thetto/core/repository")

local M = {}

M.action = function(_, _, _)
  local ctx, err = repository.get_from_path()
  if err ~= nil then
    return ""
  end

  local collector = ctx.collector
  local ui = ctx.ui

  local action_name = nil
  local offset = 0
  local item = ui:selected_items(action_name, {given = false}, offset)
  if item == nil then
    return ""
  end

  local kind_name = item.kind_name or collector.source.kind_name
  local names = kinds.actions(kind_name, collector.source.name)
  return table.concat(names, "\n")
end

M.source = function(_, _, _)
  local names = sources.names()
  return table.concat(names, "\n")
end

return M
