local modulelib = require("thetto.vendor.misclib.module")

local M = {}

local _stores = {}

--- @class ThettoStore
--- @field data fun():table
--- @field setup fun(raw_opts:table?)

--- @return ThettoStore|string
function M.new(name)
  local store = modulelib.find("thetto.handler.store." .. name)
  if not store then
    return "not found store: " .. name
  end
  _stores[name] = store
  return store
end

--- @return table
function M.get_data(name)
  local store = _stores[name]
  if store then
    return store.data()
  end
  return {}
end

return M
