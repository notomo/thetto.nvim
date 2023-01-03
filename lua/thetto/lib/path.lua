local M = {}

function M.relative_modifier(base_path)
  local pattern = "^" .. M.adjust_sep(base_path):gsub("([^%w])", "%%%1") .. "/"
  return function(path)
    return M.adjust_sep(path):gsub(pattern, "", 1)
  end
end

function M.to_relative(path, base_path)
  return M.relative_modifier(base_path)(path)
end

function M.parse_with_row(line)
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

function M.join(...)
  return table.concat({ ... }, "/")
end

function M.find_root(pattern)
  local file = vim.api.nvim_get_runtime_file("lua/" .. pattern, false)[1]
  if file == nil then
    return nil, "project root directory not found by pattern: " .. pattern
  end
  return vim.split(M.adjust_sep(file), "/lua/", { plain = true })[1], nil
end

if vim.loop.os_uname().version:match("Windows") then
  function M.adjust_sep(path)
    return path:gsub("\\", "/")
  end

  function M.home()
    return os.getenv("USERPROFILE")
  end

  M.env_separator = ";"
else
  function M.adjust_sep(path)
    return path
  end

  function M.home()
    return os.getenv("HOME")
  end

  M.env_separator = ":"
end

-- for app

function M.user_data_path(file_name)
  return vim.fn.stdpath("data") .. "/thetto.nvim/" .. file_name
end

return M
