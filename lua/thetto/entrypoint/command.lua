local engine = require "thetto/core/engine" -- more concrete naming?
local wraplib = require "thetto/lib/wrap"
local messagelib = require "thetto/lib/message"
local custom = require "thetto/custom"

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

M.open = function(raw_args)
  local default_opts = {
    insert = true,
    resume = false,
    ignorecase = false,
    smartcase = true,
    width = 100,
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
    allow_empty = false,
  }
  local source_name, opts, ex_opts, parse_err = M.parse_args(raw_args, vim.tbl_extend("force", default_opts, custom.opts))
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  if source_name == nil and not opts.resume then
    return nil, messagelib.error("no source")
  end

  local source_opts = ex_opts.x or {}
  local action_opts = ex_opts.xx or {}
  local result, err = wraplib.traceback(function()
    return engine.start(source_name, source_opts, action_opts, opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

M.execute = function(has_range, raw_range, raw_args)
  local action_name, opts, ex_opts, parse_err = M.parse_args(raw_args, {
    quit = true,
    resume = false,
    offset = 0,
  })
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  if action_name == nil then
    action_name = "default"
  end

  local range = {first = raw_range[1], last = raw_range[2], given = has_range ~= 0}
  local action_opts = ex_opts.x or {}
  local result, err = wraplib.traceback(function()
    return engine.execute(action_name, range, action_opts, opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

vim.api.nvim_command("doautocmd User ThettoSourceLoad")

return M
