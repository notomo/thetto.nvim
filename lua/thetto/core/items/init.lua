local FilterContext = require("thetto.core.items.filter_context")

local Items = {}

function Items.new(result, input_lines, filters, sorters, opts)
  local items = {}
  for _, item in result:iter() do
    table.insert(items, item)
  end

  local filter_ctx = FilterContext.new(opts.ignorecase, opts.smartcase, input_lines)
  items = filters:apply(filter_ctx, items, input_lines)
  items = sorters:apply(items)

  local filtered = {}
  for i = 1, opts.display_limit, 1 do
    filtered[i] = items[i]
  end

  local tbl = { _items = filtered, filter_ctx = filter_ctx }
  return setmetatable(tbl, Items)
end

function Items.__index(self, k)
  if type(k) == "number" then
    return self._items[k]
  end
  return Items[k]
end

function Items.iter(self)
  return ipairs(self._items)
end

function Items.values(self)
  return self._items
end

function Items.length(self)
  return vim.tbl_count(self._items)
end

return Items
