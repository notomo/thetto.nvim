local filelib = require("thetto.lib.file")

local M = {}

function M.project(target_patterns, path)
  return function()
    local patterns = target_patterns or { ".git" }
    return M.upward(patterns, path)()
  end
end

function M.upward(target_patterns, path)
  return function()
    for _, pattern in ipairs(target_patterns) do
      local found = filelib.find_upward_dir(pattern, path)
      if found ~= nil then
        return found
      end
    end
    return "."
  end
end

function M.dir(path)
  return function()
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
    return vim.fn.fnamemodify(path, ":h")
  end
end

return M
