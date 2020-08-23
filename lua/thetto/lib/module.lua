local M = {}

local find = function(path)
  local ok, module = pcall(require, path)
  if not ok then
    return nil
  end
  return module
end

-- for app

M.find_source = function(name)
  return find("thetto/source/" .. name)
end

M.find_kind = function(name)
  return find("thetto/kind/" .. name)
end

M.find_iteradapter = function(name)
  return find("thetto/iteradapter/" .. name)
end

M.find_target = function(name)
  return find("thetto/target/" .. name)
end

M.cleanup = function(name, force)
  local dir = name .. "/"
  for key in pairs(package.loaded) do
    if (vim.startswith(key, dir) or key == name) and (force or key ~= "thetto/core/persist") then
      package.loaded[key] = nil
    end
  end
  vim.api.nvim_command("doautocmd User ThettoSourceLoad")
end

return M
