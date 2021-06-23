local M = {}

local Items = {}
M.Items = Items

function Items.new(result, input_lines, filters, sorters, opts)
  local items = {}
  for _, item in result:iter() do
    table.insert(items, item)
  end

  for i, filter in filters:iter() do
    local input_line = input_lines[i]
    if input_line ~= nil and input_line ~= "" then
      items = filter:apply(items, input_line, opts)
    end
  end
  items = sorters:apply(items)

  local filtered = {}
  for i = 1, opts.display_limit, 1 do
    filtered[i] = items[i]
  end

  local tbl = {_items = filtered}
  return setmetatable(tbl, Items)
end

function Items.__index(self, k)
  if type(k) == "number" then
    return self._items[k]
  end
  return Items[k]
end

function Items.iter(self)
  return next, self._items, nil
end

function Items.values(self)
  return self._items
end

function Items.length(self)
  return vim.tbl_count(self._items)
end

return M
