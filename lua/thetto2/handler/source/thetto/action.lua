local M = {}

function M.collect()
  local items, metadata = require("thetto2").get()
  local item = items[1]

  local kind_name
  if item then
    kind_name = item.kind_name
  else
    kind_name = "base"
  end
  local kind = require("thetto2.core.kind").by_name(kind_name)

  return vim
    .iter(kind:action_infos())
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
        item = item,
      }
    end)
    :totable()
end

M.kind_name = "thetto/action"

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    start_key = "from",
  },
})

return M
