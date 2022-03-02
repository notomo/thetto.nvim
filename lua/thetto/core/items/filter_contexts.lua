local M = {}
M.__index = M

function M.new(ignorecase, smartcase, input_lines)
  local ctxs = vim.tbl_map(function(input_line)
    return M._new_one(ignorecase, smartcase, input_line)
  end, input_lines)
  local tbl = { _ctxs = ctxs }
  return setmetatable(tbl, M)
end

function M.index(self, i)
  return self._ctxs[i] or { input_line = "" }
end

function M._new_one(ignorecase, smartcase, input_line)
  if not ignorecase and smartcase and input_line:find("[A-Z]") then
    ignorecase = false
  else
    ignorecase = true
  end
  return {
    ignorecase = ignorecase,
    input_line = input_line,
  }
end

return M
