local M = {}

function M.project(target_patterns, path)
  return M.upward(target_patterns or { ".git" }, path)
end

function M.upward(target_patterns, path)
  return function()
    local root = vim.fs.root(path or ".", target_patterns)
    return root or "."
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
