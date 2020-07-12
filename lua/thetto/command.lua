local thetto = require "thetto/thetto"

local M = {}

M.parse_open_args = function(raw_args)
  local args = {
    insert = true,
    resume = false
  }

  for _, a in ipairs(raw_args) do
    if not vim.startswith(a, "--") then
      args.source_name = a
    elseif vim.startswith(a, "--no-") then
      local key = a:sub(#("--no-") + 1)
      args[key] = false
    elseif vim.startswith(a, "--") and not a:find("=") then
      local key = a:sub(#("--") + 1)
      args[key] = true
    end
  end

  if args.source_name == nil and not args.resume then
    return nil, "no source"
  end

  return args, nil
end

M.open = function(...)
  local args, parse_err = M.parse_open_args({...})
  if parse_err ~= nil then
    return vim.api.nvim_err_write(parse_err .. "\n")
  end

  local err = thetto.start(args)
  if err ~= nil then
    return vim.api.nvim_err_write(err .. "\n")
  end
end

M.parse_execute_args = function(raw_args)
  local args = {
    action = "default",
    quit = true
  }

  for _, a in ipairs(raw_args) do
    if not vim.startswith(a, "--") then
      args.action = a
    elseif vim.startswith(a, "--no-") then
      local key = a:sub(#("--no-") + 1)
      args[key] = false
    end
  end

  return args, nil
end

M.execute = function(...)
  local args, parse_err = M.parse_execute_args({...})
  if parse_err ~= nil then
    return vim.api.nvim_err_write(parse_err .. "\n")
  end

  local err = thetto.execute(args)
  if err ~= nil then
    return vim.api.nvim_err_write(err .. "\n")
  end
end

return M
