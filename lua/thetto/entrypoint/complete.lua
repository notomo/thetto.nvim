local kinds = require("thetto/core/kind")
local sources = require("thetto/core/source")
local repository = require("thetto/core/repository")

local M = {}

M.action = function(_, _, _)
  local ctx, err = repository.get_from_path()
  if err ~= nil then
    return ""
  end

  local item_group = ctx.ui:current_item_groups()[1]
  local kind_name, _ = unpack(item_group)
  local names = kinds.actions(ctx.executor, kind_name)
  return table.concat(names, "\n")
end

M.source = function(_, _, _)
  local names = sources.names()
  return table.concat(names, "\n")
end

return M
