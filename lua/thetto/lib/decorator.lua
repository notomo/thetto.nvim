local Decorator = require("thetto.vendor.misclib.decorator")

function Decorator.filter(self, hl_group, row, elements, condition)
  for i, e in ipairs(elements) do
    if condition(e) then
      self:highlight_line(hl_group, row + i - 1)
    end
  end
end

return Decorator
