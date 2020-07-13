local thetto = require "thetto/thetto"
local util = require "thetto/util"

local M = {}

M.parse_args = function(raw_args, value_name, default)
  local args = vim.deepcopy(default)

  for _, a in ipairs(raw_args) do
    if not vim.startswith(a, "--") then
      args[value_name] = a
    elseif vim.startswith(a, "--no-") then
      local key = a:sub(#("--no-") + 1)
      args[key] = false
    elseif vim.startswith(a, "--") and not a:find("=") then
      local key = a:sub(#("--") + 1)
      args[key] = true
    else
      return nil, "could not parse arg: " .. a
    end
  end

  return args, nil
end

M.open = function(...)
  local args, parse_err =
    M.parse_args(
    {...},
    "source_name",
    {
      insert = true,
      resume = false,
      width = 80,
      height = 25
    }
  )
  if parse_err ~= nil then
    return util.print_err(parse_err)
  end

  if args.source_name == nil and not args.resume then
    return util.print_err("no source")
  end

  local err = thetto.start(args)
  if err ~= nil then
    return util.print_err(err)
  end
end

M.execute = function(...)
  local args, parse_err =
    M.parse_args(
    {...},
    "action",
    {
      action = "default",
      quit = true
    }
  )
  if parse_err ~= nil then
    return util.print_err(parse_err)
  end

  local err = thetto.execute(args)
  if err ~= nil then
    return util.print_err(err)
  end
end

return M
