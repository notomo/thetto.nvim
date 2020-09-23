local M = {}

local find = function(path)
  local ok, module = pcall(require, path)
  if not ok then
    return nil
  end
  return module
end

local function set_base(target, base)
  local meta = getmetatable(target)
  if meta == nil then
    return setmetatable(target, base)
  end
  if target == meta then
    return target
  end
  return setmetatable(target, set_base(meta, base))
end
M.set_base = set_base

-- for app

M.find_source = function(name)
  return find("thetto/source/" .. name)
end

M.find_kind = function(name)
  return find("thetto/kind/" .. name)
end

M.find_filter = function(name)
  return find("thetto/iteradapter/filter/" .. name)
end

M.find_sorter = function(name)
  return find("thetto/iteradapter/sorter/" .. name)
end

M.find_target = function(name)
  return find("thetto/target/" .. name)
end

M.find_setup = function(name)
  return find("thetto/setup/" .. name)
end

local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
M.cleanup = function()
  local dir = plugin_name .. "/"
  for key in pairs(package.loaded) do
    if (vim.startswith(key, dir) or key == plugin_name) and key ~= "thetto/lib/_persist" then
      package.loaded[key] = nil
    end
  end
  vim.api.nvim_command("doautocmd User ThettoSourceLoad")
end

return M
