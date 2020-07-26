local engine = require "thetto/engine" -- more concrete naming?
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
  local ex_opts = {}

  for _, arg in ipairs(raw_args) do
    if vim.startswith(arg, "--x-") then
      local key, value = parse("--" .. arg:sub(#("--x-") + 1))
      if value == nil then
        return nil, nil, nil, "could not parse arg: " .. arg
      end
      if key == nil then
        name = value
      else
        ex_opts[key] = value
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
      args[key] = value
    end
    ::continue::
  end

  return name, args, ex_opts, nil
end

M.open = function(...)
  local source_name, args, source_opts, parse_err = M.parse_args({...}, {
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
  })
  if parse_err ~= nil then
    return nil, util.print_err(parse_err)
  end

  if source_name == nil and not args.resume then
    return nil, util.print_err("no source")
  end

  local result, err = util.with_traceback(function()
    return engine.start(source_name, source_opts, args)
  end)
  if err ~= nil then
    return nil, util.print_err(err)
  end
  return result, nil
end

M.execute = function(...)
  local action_name, args, action_opts, parse_err = M.parse_args({...}, {
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
