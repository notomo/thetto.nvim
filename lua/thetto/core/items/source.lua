local HighlighterFactory = require("thetto.lib.highlight").HighlighterFactory
local pathlib = require("thetto.lib.path")
local modulelib = require("thetto.vendor.misclib.module")
local SourceResult = require("thetto.core.items.source_result")
local base = require("thetto.handler.source.base")
local vim = vim

local Source = {}

local _registered = {}
function Source.register(name, handler)
  _registered[name] = handler
end

local find = function(name)
  local registered = _registered[name]
  if registered then
    return registered, nil
  end

  local origin = modulelib.find("thetto.handler.source." .. name)
  if origin == nil then
    return nil, "not found source: " .. name
  end

  return origin, nil
end

function Source.new(name, source_opts, opts)
  vim.validate({
    name = { name, "string" },
    source_opts = { source_opts, "table" },
    opts = { opts, "table" },
  })

  local origin, err = find(name)
  if err then
    return nil, err
  end

  local tbl = {
    name = name,
    bufnr = vim.api.nvim_get_current_buf(),
    opts = vim.tbl_extend("force", origin.opts or {}, source_opts),
    highlights = HighlighterFactory.new("thetto-list-highlight"),
    filters = opts.filters(origin.filters),
    sorters = opts.sorters(origin.sorters),
    compiled_colors = vim.tbl_map(function(color)
      return { regex = vim.regex(color.pattern), chunks = color.chunks }
    end, origin.colors or opts.colors),
    _origin = origin,
  }
  return setmetatable(tbl, Source)
end

function Source.__index(self, k)
  return rawget(Source, k) or self._origin[k] or base[k]
end

function Source.collect(self, source_ctx)
  local all_items, err = self._origin.collect(self, source_ctx)
  if err then
    return nil, err
  end

  local result, res_err = SourceResult.new(all_items)
  if res_err then
    return nil, ("%s: %s"):format(self.name, res_err)
  end

  return result, nil
end

function Source.all()
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/handler/source/**/*.lua", true)
  local already = {}
  local all = {}
  for _, path in ipairs(paths) do
    local source_file = vim.split(pathlib.adjust_sep(path), "lua/thetto/handler/source/", true)[2]
    local name = source_file:sub(1, #source_file - 4)
    if not already[name] then
      table.insert(all, {
        name = name,
        path = path,
      })
      already[name] = true
    end
  end
  return all
end

return Source
