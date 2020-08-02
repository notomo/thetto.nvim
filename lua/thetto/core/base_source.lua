local util = require("thetto/util")
local jobs = require("thetto/lib/job")
local highlights = require("thetto/view/highlight")

local M = {}

M.create = function(source_name, source_opts, opts)
  local origin = util.find_source(source_name)
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
  source.highlights = highlights

  source.highlight_sign = origin.highlight_sign or function(self, bufnr, items)
    if #compiled_colors == 0 then
      return
    end
    self.highlights.color_labels(bufnr, items, self.compiled_colors, self.color_label_key)
  end

  source.highlight = origin.highlight or function(_, _, _)
  end

  local filter_names = origin.filters or {"substring"}
  if #opts.filters ~= 0 then
    filter_names = opts.filters
  end

  local filters = {}
  for _, name in ipairs(filter_names) do
    local filter = util.find_iteradapter("filter/" .. name)
    if filter == nil then
      return nil, util.print_err("not found filter: " .. name)
    end
    table.insert(filters, filter)
  end

  local sorter_names = origin.sorters or {}
  if #opts.sorters ~= 0 then
    sorter_names = opts.sorters
  end

  local sorters = {}
  for _, name in ipairs(sorter_names) do
    local sorter = util.find_iteradapter("sorter/" .. name)
    if sorter == nil then
      return nil, util.print_err("not found sorter: " .. name)
    end
    table.insert(sorters, sorter)
  end

  source.iteradapter = {filters = filters, sorters = sorters}

  return setmetatable(source, origin), nil
end

return M
