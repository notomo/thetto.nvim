local vim = vim

local M = {}

local _colored = "xxx"

function M.collect()
  local items = {}
  local hls = vim.api.nvim_get_hl(0, {})
  for name, hl in pairs(hls) do
    local color = vim.tbl_isempty(hl) and "cleared" or vim.inspect(hl, { newline = " ", indent = "" })
    local desc = ("%s %s %s"):format(_colored, name, color)
    table.insert(items, {
      desc = desc,
      value = name,
      column_offsets = { value = #_colored + 1 },
    })
  end
  return items
end

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = function(item)
      return item.value
    end,
    end_column = #_colored,
  },
})

M.kind_name = "vim/highlight_group"

return M
