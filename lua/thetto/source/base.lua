local custom = require("thetto/custom")

local M = {}

function M.collect()
  return {}
end

function M.highlight(_, _, _)
end

function M.highlight_sign(self, bufnr, items)
  if #self.compiled_colors == 0 then
    return
  end

  local highlighter = self.sign_highlights:reset(bufnr)
  for i, item in ipairs(items) do
    for _, color in ipairs(self.compiled_colors) do
      if color.always or color.regex:match_str(item[self.color_label_key]) then
        highlighter:set_virtual_text(i - 1, color.chunks)
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
M.chunk_max_count = 10000

return M
