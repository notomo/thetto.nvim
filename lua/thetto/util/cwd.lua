local filelib = require("thetto.lib.file")

local M = {}

function M.project(target_patterns)
  return function()
    local patterns = target_patterns or { ".git" }
    return M.upward(patterns)()
  end
end

function M.upward(target_patterns)
  return function()
    for _, pattern in ipairs(target_patterns) do
      local found = filelib.find_upward_dir(pattern)
      if found ~= nil then
        return found
      end
    end
    return "."
  end
end

return M
