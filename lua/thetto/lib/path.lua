local M = {}

M.relative_modifier = function(base_path)
  local pattern = "^" .. base_path:gsub("([^%w])", "%%%1") .. "/"
  return function(path)
    return path:gsub(pattern, "", 1)
  end
end

M.to_relative = function(path, base_path)
  return M.relative_modifier(base_path)(path)
end

M.parse_with_row = function(line)
  local path, row = line:match("(.*):(%d+):")
  if not path then
    return
  end
  local matched_line = line:sub(#path + #row + #(":") * 2 + 1)
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
else
  M.adjust_sep = function(path)
    return path
  end

  M.home = function()
    return os.getenv("HOME")
  end
end

-- for app

M.user_data_path = function(file_name)
  return vim.fn.stdpath("data") .. "/thetto.nvim/" .. file_name
end

return M
