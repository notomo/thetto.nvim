local modulelib = require("thetto2.vendor.misclib.module")

local _stores = {}

local Store = {}

function Store.new(name)
  vim.validate({
    name = { name, "string" },
  })

  local store = modulelib.find("thetto2.handler.store." .. name)
  if not store then
    return nil, "not found store: " .. name
  end

  local tbl = {
    name = name,
    _store = store,
  }
  local self = setmetatable(tbl, Store)

  _stores[name] = self

  return self, nil
end

function Store.new_or_get(name)
  vim.validate({ name = { name, "string" } })
  local store = _stores[name]
  if store then
    return store
  end
  return Store.new(name)
end

function Store.__index(self, k)
  return rawget(Store, k) or self._store[k]
end

return Store
