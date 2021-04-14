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
  if target == base or target == meta then
    return target
  end
  return setmetatable(target, set_base(meta, base))
end
M.set_base = set_base

local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
function M.cleanup()
  local dir = plugin_name .. "/"
  for key in pairs(package.loaded) do
    if (vim.startswith(key, dir) or key == plugin_name) then
      package.loaded[key] = nil
    end
  end
end

-- for app

function M.find_source(name)
  return find("thetto/source/" .. name)
end

function M.find_kind(name)
  return find("thetto/kind/" .. name)
end

function M.find_filter(name)
  return find("thetto/iteradapter/filter/" .. name)
end

function M.find_sorter(name)
  return find("thetto/iteradapter/sorter/" .. name)
end

function M.find_target(name)
  return find("thetto/target/" .. name)
end

function M.find_setup(name)
  return find("thetto/setup/" .. name)
end

return M
