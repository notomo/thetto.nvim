local vim = vim

local M = {}

local colored = "xxx"

function M.collect()
  local items = {}
  local defs = vim.api.nvim__get_hl_defs(0) -- unstable api
  for name, def in pairs(defs) do
    local color = def[true] and "cleared" or vim.inspect(def, { newline = " ", indent = "" })
    local desc = ("%s %s %s"):format(colored, name, color)
    table.insert(items, {
      desc = desc,
      value = name,
      column_offsets = { value = #colored + 1 },
    })
  end
  return items
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = function(item)
      return item.value
    end,
    end_column = #colored,
  },
})

M.kind_name = "vim/highlight_group"

return M
