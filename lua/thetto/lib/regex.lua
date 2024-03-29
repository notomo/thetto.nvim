local M = {}

function M.match_any(str, patterns)
  if not str then
    return false
  end
  for _, pattern in ipairs(patterns) do
    local regex = vim.regex(pattern)
    if regex:match_str(str) then
      return true
    end
  end
  return false
end

return M
