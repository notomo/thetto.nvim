local vim = vim

local M = {}

local _colored = "xxx"

function M.collect()
  return vim
    .iter(vim.api.nvim_get_hl(0, {}))
    :map(function(name, hl)
      local color = vim.tbl_isempty(hl) and "cleared" or vim.inspect(hl, { newline = " ", indent = "" })
      local desc = ("%s %s %s"):format(_colored, name, color)
      return {
        desc = desc,
        value = name,
        column_offsets = { value = #_colored + 1 },
      }
    end)
    :totable()
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = function(item)
      return item.value
    end,
    end_column = #_colored,
  },
})

M.kind_name = "vim/highlight_group"

return M
