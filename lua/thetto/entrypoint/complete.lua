local Kind = require("thetto/core/kind").Kind
local Source = require("thetto/core/source").Source
local repository = require("thetto/core/repository")

local M = {}

M.action = function(_, _, _)
  local ctx, err = repository.get_from_path()
  if err ~= nil then
    return ""
  end

  local item_group = ctx.ui:current_item_groups()[1]
  local kind_name, _ = unpack(item_group)
  local kind = Kind.new(ctx.executor, kind_name)
  if kind == nil then
    return ""
  end

  return table.concat(kind:actions(), "\n")
end

M.source = function(_, _, _)
  return table.concat(Source.all_names(), "\n")
end

return M
