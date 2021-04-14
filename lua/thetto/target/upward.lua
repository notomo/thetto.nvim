local filelib = require("thetto/lib/file")

local M = {}

function M.cwd(target_patterns)
  for _, pattern in ipairs(target_patterns) do
    local found = filelib.find_upward_dir(pattern)
    if found ~= nil then
      return found
    end
  end
  return "."
end

return M
