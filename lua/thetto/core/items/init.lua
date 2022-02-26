local FilterContexts = require("thetto.core.items.filter_contexts")

local Items = {}

function Items.new(result, input_lines, filters, sorters, ignorecase, smartcase, display_limit)
  local items = {}
  for _, item in result:iter() do
    table.insert(items, item)
  end

  local filter_ctxs = FilterContexts.new(ignorecase, smartcase, input_lines)
  items = filters:apply(filter_ctxs, items)
  items = sorters:apply(items)

  local filtered = {}
  for i = 1, display_limit, 1 do
    filtered[i] = items[i]
  end

  local tbl = { _items = filtered, filter_ctxs = filter_ctxs }
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
