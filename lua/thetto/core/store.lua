local modulelib = require("thetto.vendor.misclib.module")
local pathlib = require("thetto.lib.path")

local _stores = {}

local Store = {}

function Store.new(name, opts)
  vim.validate({ name = { name, "string" }, opts = { opts, "table", true } })
  opts = opts or {}

  local store = modulelib.find("thetto.handler.store." .. name)
  if not store then
    return nil, "not found store: " .. name
  end

  local snake_name = name:gsub("/", "_")
  local tbl = {
    name = name,
    augroup_name = ("thetto_%s"):format(snake_name),
    file_path = opts.file_path or pathlib.user_data_path(("store_%s.txt"):format(snake_name)),
    persist = { paths = {} },
    _store = store,
  }
  local self = setmetatable(tbl, Store)
  _stores[name] = self
  return self, nil
end

function Store.__index(self, k)
  return rawget(Store, k) or self._store[k]
end

function Store.quit(self)
  _stores[self.name] = nil
  vim.api.nvim_create_augroup(self.augroup_name, {})
end

function Store.get(name)
  vim.validate({ name = { name, "string" } })
  local store = _stores[name]
  if not store then
    return nil, "no store: " .. name
  end
  return store, nil
end

function Store.new_or_get(name)
  local store = Store.get(name)
  if store then
    return store, nil
  end
  return Store.new(name)
end

return Store
