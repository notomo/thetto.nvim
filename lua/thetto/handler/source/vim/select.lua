local M = {}

M.opts = {
  items = {},
  prompt = "",
  format_item = function(item)
    return tostring(item)
  end,
  on_choice = function() end,
}

function M.collect(source_ctx)
  local items = {}
  for _, item in ipairs(source_ctx.opts.items) do
    local value = source_ctx.opts.format_item(item)
    table.insert(items, {
      value = value,
      raw = item,
      on_choice = source_ctx.opts.on_choice,
    })
  end
  return items
end

M.actions = {
  action_choose = function(items)
    local item = items[1]
    if not item then
      return
    end
    item.on_choice(item.raw)
  end,
}

M.default_action = "choose"

return M
