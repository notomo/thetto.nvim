local Kind = require("thetto2.core.kind")
local Context = require("thetto2.core.context")

local M = {}

function M.collect()
  local ctx, ctx_err = Context.get_from_path()
  if ctx_err ~= nil then
    return nil, "must be executed in thetto buffer"
  end

  local item = ctx.ui:selected_items()[1] or {}
  local kind_name = item.kind_name or ctx.collector.source.kind_name
  local kind = Kind.new(ctx.executor, kind_name)

  local items = {}
  local source_name = ctx.collector.source.name
  for _, action_info in ipairs(kind:action_infos()) do
    local action_name = action_info.name
    local quit = (kind.behaviors[action_name] or {}).quit or false
    local desc = ("%s (%s)"):format(action_name, action_info.from)
    table.insert(items, {
      value = action_name,
      desc = desc,
      source_name = source_name,
      quit = quit,
      column_offsets = {
        value = 0,
        from = #action_name + 1,
      },
    })
  end
  return items
end

M.kind_name = "thetto/action"

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    start_key = "from",
  },
})

return M
