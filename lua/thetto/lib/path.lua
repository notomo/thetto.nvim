local M = {}

M.relative_modifier = function(base_path)
  local pattern = "^" .. base_path:gsub("([^%w])", "%%%1") .. "/"
  return function(path)
    return path:gsub(pattern, "", 1)
  end
end

-- for app

M.user_data_path = function(file_name)
  return vim.fn.stdpath("data") .. "/thetto.nvim/" .. file_name
end

return M
