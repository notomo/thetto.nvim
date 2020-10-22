local M = {}

M.relative_modifier = function(base_path)
  local pattern = "^" .. M.adjust_sep(base_path):gsub("([^%w])", "%%%1") .. "/"
  return function(path)
    return M.adjust_sep(path):gsub(pattern, "", 1)
  end
end

M.to_relative = function(path, base_path)
  return M.relative_modifier(base_path)(path)
end

M.parse_with_row = function(line)
  local row = line:match(":(%d+):")
  if not row then
    return
  end

  local row_pattern = (":%s:"):format(row)
  local row_index = line:find(row_pattern)

  local path = line:sub(1, row_index - 1)
  local matched_line = line:sub(row_index + #row_pattern)
  return path, tonumber(row), matched_line
end

M.join = function(...)
  return table.concat({...}, "/")
end

if vim.fn.has("win32") == 1 then
  M.adjust_sep = function(path)
    return path:gsub("\\", "/")
  end

  M.home = function()
    return os.getenv("USERPROFILE")
  end

  M.env_separator = ";"
else
  M.adjust_sep = function(path)
    return path
  end

  M.home = function()
    return os.getenv("HOME")
  end

  M.env_separator = ":"
end

-- for app

M.user_data_path = function(file_name)
  return vim.fn.stdpath("data") .. "/thetto.nvim/" .. file_name
end

return M
