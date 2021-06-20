local modulelib = require("thetto/lib/module")
local pathlib = require("thetto/lib/path")
local repository = require("thetto/lib/repository").Repository.new("store")

local M = {}

local Store = {}
M.Store = Store

function Store.new(name, opts)
  vim.validate({name = {name, "string"}, opts = {opts, "table", true}})
  opts = opts or {}

  local store = modulelib.find("thetto/handler/store/" .. name)
  if not store then
    return nil, "not found store: " .. name
  end

  local snake_name = name:gsub("/", "_")
  local tbl = {
    name = name,
    augroup_name = ("thetto_%s"):format(snake_name),
    file_path = opts.file_path or pathlib.user_data_path(("store_%s.txt"):format(snake_name)),
    persist = {paths = {}},
    _store = store,
  }
  local self = setmetatable(tbl, Store)
  repository:set(name, self)
  return self, nil
end

function Store.__index(self, k)
  return rawget(Store, k) or self._store[k]
end

function Store.quit(self)
  repository:delete(self.name)
  vim.cmd("silent! augroup! " .. self.augroup_name)
end

function Store.get(name)
  vim.validate({name = {name, "string"}})
  local store = repository:get(name)
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

return M
