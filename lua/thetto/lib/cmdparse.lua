local M = {}

local parse = function(arg)
  local has_equal = arg:find("=")
  if not vim.startswith(arg, "--") then
    return nil, arg
  elseif vim.startswith(arg, "--no-") then
    local key = arg:sub(#("--no-") + 1):gsub("-", "_")
    return key, false
  elseif vim.startswith(arg, "--") and not has_equal then
    local key = arg:sub(#("--") + 1):gsub("-", "_")
    return key, true
  elseif vim.startswith(arg, "--") and has_equal then
    local key = arg:sub(#("--") + 1, has_equal - 1):gsub("-", "_")
    local value = arg:sub(has_equal + 1)
    if value:match("^%d+$") then
      return key, tonumber(value)
    end
    return key, value
  end
  return nil, nil
end

M.args = function(raw_args, default)
  local name = nil
  local opts = vim.deepcopy(default)
  local ex_opts = {x = {}, xx = {}}

  for _, arg in ipairs(raw_args) do
    if vim.startswith(arg, "--x-") then
      local key, value = parse("--" .. arg:sub(#("--x-") + 1))
      if key == nil then
        return nil, nil, nil, "could not parse arg: " .. arg
      end

      local current = ex_opts.x[key]
      if type(current) == "table" then
        table.insert(ex_opts.x[key], value)
      else
        ex_opts.x[key] = value
      end

      goto continue
    end

    if vim.startswith(arg, "--xx-") then
      local key, value = parse("--" .. arg:sub(#("--xx-") + 1))
      if key == nil then
        return nil, nil, nil, "could not parse arg: " .. arg
      end

      local current = ex_opts.xx[key]
      if type(current) == "table" then
        table.insert(ex_opts.xx[key], value)
      else
        ex_opts.xx[key] = value
      end

      goto continue
    end

    local key, value = parse(arg)
    if value == nil then
      return nil, nil, nil, "could not parse arg: " .. arg
    end
    if key == nil then
      name = value
    else
      local current = opts[key]
      if type(current) == "table" then
        table.insert(opts[key], value)
      else
        opts[key] = value
      end
    end
    ::continue::
  end

  return name, opts, ex_opts, nil
end

return M
