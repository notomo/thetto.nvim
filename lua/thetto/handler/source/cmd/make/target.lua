local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")

local M = {}

local to_item = function(path, target, row, included_from, cwd)
  if target == "" or target == ".PHONY" or (target or ""):find(":") ~= nil then
    return nil
  end

  local relative_path = pathlib.to_relative(path, cwd)
  local path_row = ("%s:%d"):format(relative_path, row)
  local desc = ("%s %s"):format(path_row, target or "(no)")
  return {
    desc = desc,
    value = target or "",
    path = path,
    included_from = included_from,
    row = row,
    column_offsets = { value = #path_row + 1 },
  }
end

local expand = function(str, variables)
  return (str:gsub("%$[%(%{]([%w_]+)[%)%}]", function(name)
    return variables[name] or vim.env[name] or ""
  end))
end

function M._parse_variable(line, variables)
  local name, operator, value = line:match("^([%w_]+)%s*([?:]?=)%s*(.-)%s*$")
  if not name then
    return
  end

  if operator == "?=" and (variables[name] or vim.env[name]) then
    return
  end

  variables[name] = expand(value, variables)
end

function M._load(path, cwd, included_from, variables)
  if not filelib.readable(path) then
    return {}
  end

  variables = variables or {}

  local items = {}
  local row = 1
  local f = io.open(path, "r")
  assert(f, "failed to open: " .. path)
  local dir_path = vim.fs.dirname(path)
  for line in f:lines() do
    M._parse_variable(line, variables)
    vim.list_extend(items, M._parse_include(line, dir_path, path, variables))

    local target = vim.fn.matchstr(line, "\\v^\\zs\\S*\\ze:[^=]*$")
    table.insert(items, to_item(path, target, row, included_from, cwd))
    row = row + 1
  end
  f:close()

  return items
end

function M._parse_include(line, dir_path, included_from, variables)
  local included = line:match("^include (.+)")
  if not included then
    return {}
  end

  local included_path = expand(included, variables or {})
  local path =
    vim.fn.simplify(vim.startswith(included_path, "/") and included_path or (dir_path .. "/" .. included_path))
  if not filelib.readable(path) then
    return {}
  end

  return M._load(path, dir_path, included_from, variables)
end

function M.collect(source_ctx)
  local path = vim.fs.joinpath(source_ctx.cwd, "Makefile")
  local dir_path = vim.fs.dirname(path)
  local paths = vim.fn.glob(dir_path .. "/*.mk", false, true)

  local items = {}
  for _, p in ipairs(vim.list_extend({ path }, paths)) do
    local item = to_item(path, nil, 1, nil, source_ctx.cwd)
    table.insert(items, item)
    items = vim.list_extend(items, M._load(p, source_ctx.cwd))
  end
  return items
end

vim.api.nvim_set_hl(0, "ThettoMakeTargetPath", { default = true, link = "Comment" })

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "ThettoMakeTargetPath",
    end_key = "value",
  },
})

M.kind_name = "cmd/make/target"

M.cwd = require("thetto.util.cwd").upward({ "Makefile" })

M.consumer_opts = {
  ui = { insert = false },
}

return M
