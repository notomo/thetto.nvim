local custom = require("thetto/custom")

local M = {}

M.collect = function()
  return {}
end

M.highlight = function(_, _, _)
end

M.highlight_sign = function(self, bufnr, items)
  if #self.compiled_colors == 0 then
    return
  end

  local highlighter = self.sign_highlights:reset(bufnr)
  for i, item in ipairs(items) do
    for _, color in ipairs(self.compiled_colors) do
      if color.always or color.regex:match_str(item[self.color_label_key]) then
        highlighter:set_virtual_text(i - 1, color.chunks, {})
        break
      end
    end
  end
end

M.color_label_key = "value"
M.colors = {{always = true, pattern = "", chunks = {{" ", "ThettoColorLabelOthers"}}}}
M.filters = custom.default_filters or {"substring"}
M.sorters = custom.default_sorters or {}
M.kind_name = "base"
M.opts = {}

M.__index = M

return M
