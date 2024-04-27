local M = {}

function M.apply(_, items, opts)
  table.sort(items, function(item_a, item_b)
    for _, convert in ipairs(opts.converts) do
      local a = convert.to(item_a, convert.opts)
      local b = convert.to(item_b, convert.opts)
      if a ~= b then
        return (a > b and convert.reversed) or not (a > b or convert.reversed)
      end
    end
    return false
  end)
  return items
end

M.opts = {
  converts = {},
}

M.is_sorter = true
M.ignore_input = true

return M
