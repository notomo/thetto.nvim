local Kind = require("thetto.core.kind").Kind
local Context = require("thetto.core.context").Context

local M = {}

function M.collect()
  local ctx, ctx_err = Context.get_from_path()
  if ctx_err ~= nil then
    return nil, nil, "must be executed in thetto buffer"
  end

  local item = ctx.ui:selected_items()[1] or {}
  local kind_name = item.kind_name or ctx.collector.source.kind_name
  local kind = Kind.new(ctx.executor, kind_name)

  local items = {}
  local source_name = ctx.collector.source.name
  for _, action_name in ipairs(kind:action_names()) do
    table.insert(items, {value = action_name, source_name = source_name})
  end
  return items
end

M.kind_name = "thetto/action"

return M
