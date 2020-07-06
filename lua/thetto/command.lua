local thetto = require "thetto/thetto"

local M = {}

M.parse_args = function(raw_args)
  local args = {
    action_name = "default"
  }
  for _, a in ipairs(raw_args) do
    if not vim.startswith(a, "--") then
      args.source_name = a
      break
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

M.main = function(...)
  local args, err = M.parse_args({...})
  if err ~= nil then
    return vim.api.nvim_err_write(err .. "\n")
  end

  local source = M.find_source(args)
  if source == nil then
    return
  end

  local width = 80
  local height = 25
  local row = vim.o.lines / 2 - (height / 2)
  local col = vim.o.columns / 2 - (width / 2)
  opts = {
    row = row,
    column = col,
    width = width,
    height = height,
    action_name = args.action_name
  }

  thetto.start(source, opts)
end

return M
