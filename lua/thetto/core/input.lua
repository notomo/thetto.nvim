local M = {}

local pattern_types = {
  word = function()
    return vim.fn.expand("<cword>")
  end,
  path = function()
    return vim.fn.expand("<cfile>")
  end,
}

function M.get(typ)
  local fn = pattern_types[typ]
  if fn == nil then
    return nil, "not found input type: " .. typ
  end
  return fn(), nil
end

return M
