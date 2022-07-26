local FilterContexts = require("thetto.core.items.filter_contexts")

local Items = {}

function Items.new(result, input_lines, filters, sorters, ignorecase, smartcase, display_limit, page, page_offset)
  page_offset = page_offset or 0

  local items = {}
  for _, item in result:iter() do
    table.insert(items, item)
  end

  local filter_ctxs = FilterContexts.new(ignorecase, smartcase, input_lines)
  items = filters:apply(filter_ctxs, items)
  items = sorters:apply(items)

  local filtered = {}
  local item_count = #items

  page = page or 0
  page = math.max(0, page + page_offset)
  page = math.min(page, math.floor(item_count / display_limit))

  local start_index = 1 + display_limit * page
  start_index = math.min(item_count, start_index)

  local end_index = display_limit * (page + 1)
  end_index = math.min(item_count, end_index)

  local index = 1
  for i = start_index, end_index, 1 do
    filtered[index] = items[i]
    index = index + 1
  end

  local tbl = {
    _items = filtered,
    filter_ctxs = filter_ctxs,
    page = page,
    start_index = start_index,
    end_index = end_index,
    display_limit = display_limit,
  }
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
