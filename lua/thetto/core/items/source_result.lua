local M = {}

local SourceResult = {}
SourceResult.__index = SourceResult
M.SourceResult = SourceResult

local SourcePendingResult = {}

function SourcePendingResult.__index(_, k)
  return rawget(SourcePendingResult, k) or rawget(SourceResult, k)
end

function SourcePendingResult.start(self)
  if self._job:is_running() then
    return
  end
  return self._job:start()
end

function SourcePendingResult.stop(self)
  self._job:stop()
end

function SourcePendingResult.wait(self, ms)
  ms = ms or 1000
  return vim.wait(ms, function()
    return self:finished()
  end, 10)
end

function SourcePendingResult.discard(self)
  self._job:discard()
end

function SourcePendingResult.finished(self)
  return not self._job:is_running()
end

function SourceResult.new(name, all_items, job, empty_is_err)
  vim.validate({
    name = { name, "string" },
    all_items = { all_items, "table", true },
    job = { job, "table", true },
    empty_is_err = { empty_is_err, "boolean", true },
  })
  all_items = all_items or {}

  if job ~= nil then
    local tbl = { _job = job, _all_items = {} }
    return setmetatable(tbl, SourcePendingResult)
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

function SourceResult.stop(_) end

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

function SourceResult.reset(self)
  self._all_items = {}
end

function SourceResult.apply_selected(self, items)
  for _, item in items:iter() do
    if item.selected ~= nil then
      self._all_items[item.index].selected = item.selected
    end
  end
end

return M
