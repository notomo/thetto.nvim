local HighlighterFactory = require("thetto.lib.highlight").HighlighterFactory
local jobs = require("thetto.lib.job")
local pathlib = require("thetto.lib.path")
local modulelib = require("thetto.vendor.misclib.module")
local SourceResult = require("thetto.core.items.source_result")
local base = require("thetto.handler.source.base")
local vim = vim

local Source = {
  errors = { skip_empty_pattern = "skip_empty_pattern" },
  jobs = jobs,
}

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

function Source.collect(self, source_ctx, append, reset)
  self.append = function(_, items)
    return append(items)
  end
  self.reset = reset

  local all_items, job, err = self._origin.collect(self, source_ctx)
  if err ~= nil and err ~= Source.errors.skip_empty_pattern then
    return nil, err
  end

  local empty_is_err = not (source_ctx.interactive and err == Source.errors.skip_empty_pattern)
  local result, res_err = SourceResult.new(self.name, all_items, job, empty_is_err)
  if res_err ~= nil then
    return nil, res_err
  end

  local start_err = result:start()
  if start_err ~= nil then
    return nil, start_err
  end

  return result, nil
end

function Source.all_names()
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/handler/source/**/*.lua", true)
  local already = {}
  local names = {}
  for _, path in ipairs(paths) do
    local source_file = vim.split(pathlib.adjust_sep(path), "lua/thetto/handler/source/", true)[2]
    local name = source_file:sub(1, #source_file - 4)
    if not already[name] then
      table.insert(names, name)
      already[name] = true
    end
  end
  return names
end

return Source
