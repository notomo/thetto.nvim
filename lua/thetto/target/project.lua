local M = {}

M.root_patterns = {".git"}

M.cwd = function()
  for _, pattern in ipairs(M.root_patterns) do
    local found = vim.fn.finddir(pattern, ".;")
    if found ~= nil then
      local root = vim.fn.fnamemodify(found, ":p:h:h")
      return root
    end
  end
  return "."
end

return M
