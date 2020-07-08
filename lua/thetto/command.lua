local thetto = require "thetto/thetto"

local M = {}

M.parse_open_args = function(raw_args)
  local args = {
    insert = true
  }

  for _, a in ipairs(raw_args) do
    if not vim.startswith(a, "--") then
      args.source_name = a
    elseif vim.startswith(a, "--no-") then
      local key = a:sub(#("--no-") + 1)
      args[key] = false
    end
  end

  if args.source_name == nil then
    return nil, "no source"
  end

  return args, nil
end

M.find_source = function(args)
  local name = ("thetto/source/%s"):format(args.source_name)
  local ok, module = pcall(require, name)
  if not ok then
    return nil
  end
  return module
end

M.open = function(...)
  local args, err = M.parse_open_args({...})
  if err ~= nil then
    return vim.api.nvim_err_write(err .. "\n")
  end

  local source = M.find_source(args)
  if source == nil then
    return
  end

  local opts = args
  opts.width = 80
  opts.height = 25
  opts.row = vim.o.lines / 2 - (opts.height / 2)
  opts.column = vim.o.columns / 2 - (opts.width / 2)

  thetto.start(source, opts)
end

M.parse_execute_args = function(raw_args)
  local args = {
    action = "default"
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
  local args, err = M.parse_execute_args({...})
  if err ~= nil then
    return vim.api.nvim_err_write(err .. "\n")
  end

  return thetto.execute(args)
end

return M
