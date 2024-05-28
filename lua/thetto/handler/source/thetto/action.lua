local M = {}

--- @param source_ctx ThettoSourceContext
function M.collect(source_ctx)
  if not source_ctx.store_to_restart then
    local items, metadata = require("thetto").get()
    source_ctx.store_to_restart = { items, metadata }
  end

  local items, metadata = unpack(source_ctx.store_to_restart)
  local item = items[1]

  local kind_name
  if item then
    kind_name = item.kind_name
  else
    kind_name = "base"
  end
  local kind = require("thetto.core.kind").by_name(kind_name, metadata.actions)

  return vim
    .iter(require("thetto.core.kind").action_infos(kind))
    :map(function(action_info)
      local action_name = action_info.name
      local desc = ("%s (%s)"):format(action_name, action_info.from)
      return {
        value = action_name,
        desc = desc,
        column_offsets = {
          value = 0,
          from = #action_name + 1,
        },
        metadata = metadata,
        items = items,
      }
    end)
    :totable()
end

M.kind_name = "thetto/action"

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    start_key = "from",
  },
})

return M
