local highlights = require("thetto/lib/highlight")
local jobs = require("thetto/lib/job")
local pathlib = require("thetto/lib/path")
local filelib = require("thetto/lib/file")
local listlib = require("thetto/lib/list")
local modulelib = require("thetto/lib/module")
local custom = require("thetto/custom")

local M = {}

M.create = function(notifier, source_name, source_opts, opts)
  local origin = modulelib.find_source(source_name)
  if origin == nil then
    return nil, "not found source: " .. source_name
  end
  origin.__index = origin

  local source = {}
  source.name = source_name
  source.opts = vim.tbl_extend("force", origin.opts or {}, source_opts)
  source.color_label_key = origin.color_label_key or "value"
  source.colors = origin.colors or {
    {always = true, pattern = "", chunks = {{" ", "ThettoColorLabelOthers"}}},
  }

  local compiled_colors = {}
  for _, color in ipairs(source.colors) do
    table.insert(compiled_colors, {regex = vim.regex(color.pattern), chunks = color.chunks})
  end
  source.compiled_colors = compiled_colors

  source.jobs = jobs
  source.highlights = highlights.new_factory("thetto-list-highlight")
  source.pathlib = pathlib
  source.filelib = filelib
  source.listlib = listlib

  local label_factory = highlights.new_factory("thetto-sign-highlight")
  source.highlight_sign = origin.highlight_sign or function(self, bufnr, items)
    if #compiled_colors == 0 then
      return
    end

    local highlighter = label_factory:reset(bufnr)
    for i, item in ipairs(items) do
      for _, color in ipairs(self.compiled_colors) do
        if color.always or color.regex:match_str(item[self.color_label_key]) then
          highlighter:set_virtual_text(i - 1, color.chunks, {})
          break
        end
      end
    end
  end

  source.highlight = origin.highlight or function(_, _, _)
  end

  source.append = function(items)
    notifier:send("update_all_items", items)
  end

  local filter_names = origin.filters or custom.default_filters or {"substring"}
  if #opts.filters ~= 0 then
    filter_names = opts.filters
  end
  source.filters = filter_names

  local sorter_names = origin.sorters or custom.default_sorters or {}
  if #opts.sorters ~= 0 then
    sorter_names = opts.sorters
  end
  source.sorters = sorter_names

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
