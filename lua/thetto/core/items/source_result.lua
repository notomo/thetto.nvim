local SourceResult = {}
SourceResult.__index = SourceResult

local SourceFunctionResult = {}

function SourceFunctionResult.__index(_, k)
  return rawget(SourceFunctionResult, k) or rawget(SourceResult, k)
end

function SourceFunctionResult.start(self)
  local observable = require("thetto.vendor.misclib.observable").new(self._subscriber)
  local subscription = observable:subscribe({
    next = function(items)
      self._append(items)
    end,
    error = function(err)
      self._append({})
      require("thetto.vendor.misclib.message").warn(err)
    end,
    complete = function()
      self._append({})
    end,
  })
  self._subscription = subscription
end

function SourceFunctionResult.wait(self, ms)
  ms = ms or 1000
  return vim.wait(ms, function()
    return self:finished()
  end, 10)
end

function SourceFunctionResult.discard(self)
  return self._subscription and self._subscription:unsubscribe()
end

function SourceFunctionResult.finished(self)
  return self._subscription and self._subscription:closed()
end

function SourceResult.new(name, all_items, empty_is_err, append)
  vim.validate({
    name = { name, "string" },
    all_items = { all_items, { "table", "function" }, true },
    empty_is_err = { empty_is_err, "boolean", true },
    append = { append, "function", true },
  })
  all_items = all_items or {}

  if type(all_items) == "function" then
    local tbl = { _subscriber = all_items, _all_items = {}, _append = append }
    return setmetatable(tbl, SourceFunctionResult)
  end

  if empty_is_err and #all_items == 0 then
    return nil, name .. ": empty"
  end

  for i, item in ipairs(all_items) do
    item.index = i
  end
  local tbl = { _all_items = all_items }
  return setmetatable(tbl, SourceResult)
end

function SourceResult.start(_)
  return nil
end

function SourceResult.wait(_)
  return true
end

function SourceResult.discard(_) end

function SourceResult.finished(_)
  return true
end

function SourceResult.iter(self)
  return ipairs(self._all_items)
end

function SourceResult.count(self)
  return #self._all_items
end

function SourceResult.append(self, items)
  local len = #self._all_items
  for i, item in ipairs(items) do
    item.index = len + i
  end
  vim.list_extend(self._all_items, items)
end

function SourceResult.apply_selected(self, items)
  for _, item in items:iter() do
    if item.selected ~= nil then
      self._all_items[item.index].selected = item.selected
    end
  end
end

return SourceResult
