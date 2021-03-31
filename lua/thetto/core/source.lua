local highlights = require("thetto/lib/highlight")
local jobs = require("thetto/lib/job")
local pathlib = require("thetto/lib/path")
local filelib = require("thetto/lib/file")
local listlib = require("thetto/lib/list")
local modulelib = require("thetto/lib/module")
local SourceResult = require("thetto/core/source_result").SourceResult
local base = require("thetto/source/base")
local vim = vim

local M = {}

local Source = {}
M.Source = Source

Source.errors = {skip_empty_pattern = "skip_empty_pattern"}
Source.jobs = jobs
Source.pathlib = pathlib
Source.filelib = filelib
Source.listlib = listlib

function Source.new(name, source_opts, opts)
  vim.validate({
    name = {name, "string"},
    source_opts = {source_opts, "table"},
    opts = {opts, "table"},
  })

  local origin = modulelib.find_source(name)
  if origin == nil then
    return nil, "not found source: " .. name
  end

  local tbl = {
    name = name,
    opts = vim.tbl_extend("force", origin.opts or base.opts, source_opts),
    highlights = highlights.new_factory("thetto-list-highlight"),
    sign_highlights = highlights.new_factory("thetto-sign-highlight"),
    filters = nil,
    sorters = nil,
    bufnr = vim.api.nvim_get_current_buf(),
    compiled_colors = vim.tbl_map(function(color)
      return {regex = vim.regex(color.pattern), chunks = color.chunks}
    end, origin.colors or base.colors),
    ctx = {},
    _origin = origin,
  }
  if #opts.filters ~= 0 then
    tbl.filters = opts.filters
  end
  if #opts.sorters ~= 0 then
    tbl.sorters = opts.sorters
  end

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
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/source/**/*.lua", true)
  return vim.tbl_map(function(path)
    local source_file = vim.split(pathlib.adjust_sep(path), "lua/thetto/source/", true)[2]
    return source_file:sub(1, #source_file - 4)
  end, paths)
end

return M
