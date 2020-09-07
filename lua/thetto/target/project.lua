local upward_target = require("thetto/target/upward")

local M = {}

M.root_patterns = {".git"}

M.cwd = function(target_patterns)
  local patterns = M.root_patterns
  if #target_patterns > 0 then
    patterns = target_patterns
  end
  return upward_target.cwd(patterns)
end

return M
