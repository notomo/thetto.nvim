local highlights = require("thetto/lib/highlight")
local jobs = require("thetto/lib/job")
local pathlib = require("thetto/lib/path")
local filelib = require("thetto/lib/file")
local listlib = require("thetto/lib/list")
local modulelib = require("thetto/lib/module")
local base = require("thetto/source/base")

local M = {}

M.create = function(notifier, source_name, source_opts, opts)
  local origin
  if source_name == "base" then
    origin = base
  else
    local found = modulelib.find_source(source_name)
    if found == nil then
      return nil, "not found source: " .. source_name
    end
    origin = setmetatable(found, base)
    origin.__index = origin
  end

  local source = {}
  source.name = source_name
  source.opts = vim.tbl_extend("force", origin.opts, source_opts)
  source.jobs = jobs
  source.highlights = highlights.new_factory("thetto-list-highlight")
  source.sign_highlights = highlights.new_factory("thetto-sign-highlight")
  source.pathlib = pathlib
  source.filelib = filelib
  source.listlib = listlib

  if #opts.filters ~= 0 then
    source.filters = opts.filters
  end
  if #opts.sorters ~= 0 then
    source.sorters = opts.sorters
  end

  local compiled_colors = {}
  for _, color in ipairs(origin.colors) do
    table.insert(compiled_colors, {regex = vim.regex(color.pattern), chunks = color.chunks})
  end
  source.compiled_colors = compiled_colors

  source.append = function(items)
    notifier:send("update_all_items", items)
  end

  return setmetatable(source, origin), nil
end

M.names = function()
  local names = {}
  local paths = vim.api.nvim_get_runtime_file("lua/thetto/source/**/*.lua", true)
  for _, path in ipairs(paths) do
    local source_file = vim.split(path, "lua/thetto/source/", true)[2]
    local name = source_file:sub(1, #source_file - 4)
    table.insert(names, name)
  end
  return names
end

return M
