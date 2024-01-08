local M = {}

M.opts = {
  items = {},
  prompt = "",
  format_item = function(item)
    return tostring(item)
  end,
  on_choice = function() end,
  get_range = function(_)
    return nil
  end,
}

function M.collect(source_ctx)
  local items = {}
  for _, item in ipairs(source_ctx.opts.items) do
    local value = source_ctx.opts.format_item(item)
    local desc = ("%s %s"):format(source_ctx.opts.prompt, value)
    local range = source_ctx.opts.get_range(item) or { s = {}, e = {} }
    table.insert(items, {
      value = value,
      desc = desc,
      raw = item,
      row = range.s.row,
      end_row = range.e.row,
      on_choice = source_ctx.opts.on_choice,
      column_offsets = {
        value = #source_ctx.opts.prompt + 1,
      },
    })
  end
  return items
end

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    end_key = "value",
  },
})

M.actions = {
  action_choose = function(items)
    local item = items[1]
    if not item then
      return
    end
    item.on_choice(item.raw)
  end,

  default_action = "choose",
}

return M
