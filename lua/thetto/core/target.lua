local filelib = require("thetto.lib.file")

local M = {}

local Target = {}

M.project_root_patterns = {".git"}

function Target.project(target_patterns)
  local patterns = M.project_root_patterns
  if #target_patterns > 0 then
    patterns = target_patterns
  end
  return Target.upward(patterns)
end

function Target.upward(target_patterns)
  for _, pattern in ipairs(target_patterns) do
    local found = filelib.find_upward_dir(pattern)
    if found ~= nil then
      return found
    end
  end
  return "."
end

function M.get(typ, target_patterns)
  local fn = Target[typ]
  if fn == nil then
    return nil, "not found target type: " .. typ
  end
  return fn(target_patterns), nil
end

return M
