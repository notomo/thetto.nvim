local HighlighterFactory = require("thetto.lib.highlight").HighlighterFactory
local jobs = require("thetto.lib.job")
local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")
local listlib = require("thetto.lib.list")
local timelib = require("thetto.lib.time")
local modulelib = require("thetto.lib.module")
local SourceResult = require("thetto.core.source_result").SourceResult
local base = require("thetto.handler.source.base")
local vim = vim

local M = {}

local Source = {
  errors = { skip_empty_pattern = "skip_empty_pattern" },
  jobs = jobs,
  pathlib = pathlib,
  filelib = filelib,
  listlib = listlib,
  timelib = timelib,
}
M.Source = Source

function Source.new(name, source_opts, opts)
  vim.validate({
    name = { name, "string" },
    source_opts = { source_opts, "table" },
    opts = { opts, "table" },
  })

  local origin = modulelib.find("thetto.handler.source." .. name)
  if origin == nil then
    return nil, "not found source: " .. name
  end

  local config = require("thetto.core.custom").config
  local source_config = config.source[name] or {}
  local tbl = {
    name = name,
    opts = vim.tbl_extend("force", origin.opts or base.opts, source_config.opts or {}, source_opts),
    highlights = HighlighterFactory.new("thetto-list-highlight"),
    filters = opts.filters or source_config.filters or origin.filters or config.filters,
    sorters = opts.sorters or source_config.sorters or origin.sorters or config.sorters,
    bufnr = vim.api.nvim_get_current_buf(),
    compiled_colors = vim.tbl_map(function(color)
      return { regex = vim.regex(color.pattern), chunks = color.chunks }
    end, origin.colors or source_config.colors or base.colors),
    ctx = {},
    _origin = origin,
  }

  return setmetatable(tbl, Source)
end

function Source.__index(self, k)
  return rawget(Source, k) or self._origin[k] or base[k]
end

function Source.collect(self, opts, append, reset)
  self.append = function(_, items, source_ctx)
    local err = append(items)
    if err ~= nil then
      return err
    end
    if source_ctx ~= nil then
      self.ctx = source_ctx
    end
  end
  self.reset = reset

  local all_items, job, err = self._origin.collect(self, opts)
  if err ~= nil and err ~= Source.errors.skip_empty_pattern then
    return nil, err
  end

  local empty_is_err = not ((opts.interactive and err == Source.errors.skip_empty_pattern) or opts.allow_empty)
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

return M
