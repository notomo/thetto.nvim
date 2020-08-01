local engine = require "thetto/core/engine" -- more concrete naming?
local util = require "thetto/util"

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

M.parse_args = function(raw_args, default)
  local name = nil
  local args = vim.deepcopy(default)
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
      local current = args[key]
      if type(current) == "table" then
        table.insert(args[key], value)
      else
        args[key] = value
      end
    end
    ::continue::
  end

  return name, args, ex_opts, nil
end

M.open = function(...)
  local source_name, args, ex_opts, parse_err = M.parse_args({...}, {
    insert = true,
    resume = false,
    ignorecase = false,
    smartcase = true,
    width = 90,
    height = 25,
    pattern = nil,
    pattern_type = nil,
    offset = 0,
    cwd = ".",
    target = nil,
    action = nil,
    display_limit = 100,
    debounce_ms = 50,
    filters = {},
    sorters = {},
  })
  if parse_err ~= nil then
    return nil, util.print_err(parse_err)
  end

  if source_name == nil and not args.resume then
    return nil, util.print_err("no source")
  end

  local source_opts = ex_opts.x or {}
  local action_opts = ex_opts.xx or {}
  local result, err = util.with_traceback(function()
    return engine.start(source_name, source_opts, action_opts, args)
  end)
  if err ~= nil then
    return nil, util.print_err(err)
  end
  return result, nil
end

M.execute = function(...)
  local action_name, args, ex_opts, parse_err = M.parse_args({...}, {
    quit = true,
    resume = false,
    offset = 0,
  })
  if parse_err ~= nil then
    return nil, util.print_err(parse_err)
  end

  if action_name == nil then
    action_name = "default"
  end

  local action_opts = ex_opts.x or {}
  local result, err = util.with_traceback(function()
    return engine.execute(action_name, action_opts, args)
  end)
  if err ~= nil then
    return nil, util.print_err(err)
  end
  return result, nil
end

vim.api.nvim_command("doautocmd User ThettoSourceLoad")

return M
