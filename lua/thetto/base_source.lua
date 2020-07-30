local util = require("thetto/util")
local jobs = require("thetto/job")
local highlights = require("thetto/highlight")

local M = {}

M.create = function(source_name, source_opts)
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

  return setmetatable(source, origin), nil
end

return M
