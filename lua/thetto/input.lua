local M = {}

local types = {
  word = function()
    return vim.fn.expand("<cword>")
  end,
  path = function()
    return vim.fn.expand("<cfile>")
  end,
}

M.get = function(pattern_type)
  return types[pattern_type]()
end

return M
