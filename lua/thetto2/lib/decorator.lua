local Decorator = require("thetto2.vendor.misclib.decorator")

local highlight_opts = {
  priority = vim.highlight.priorities.user - 1,
}

function Decorator.filter(self, hl_group, row, elements, condition)
  for i, e in ipairs(elements) do
    if condition(e) then
      self:highlight_line(hl_group, row + i - 1, highlight_opts)
    end
  end
end

return Decorator
