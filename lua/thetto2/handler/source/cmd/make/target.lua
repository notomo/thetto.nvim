local pathlib = require("thetto2.lib.path")
local filelib = require("thetto2.lib.file")

local M = {}

function M._load(path, cwd, included_from)
  if not filelib.readable(path) then
    return {}
  end

  local items = {}
  local row = 1
  local f = io.open(path, "r")
  local dir_path = vim.fs.dirname(path)
  local to_relative = pathlib.relative_modifier(cwd)
  for line in f:lines() do
    vim.list_extend(items, M._parse_include(line, dir_path, path))

    local target = vim.fn.matchstr(line, "\\v^\\zs\\S*\\ze:[^=]*$")
    if not (target == "" or target == ".PHONY" or target:find(":") ~= nil) then
      local path_row = ("%s:%d"):format(to_relative(path), row)
      local desc = ("%s %s"):format(path_row, target)
      table.insert(items, {
        desc = desc,
        value = target,
        path = path,
        included_from = included_from,
        row = row,
        column_offsets = { value = #path_row + 1 },
      })
    end
    row = row + 1
  end
  f:close()

  return items
end

function M._parse_include(line, dir_path, included_from)
  -- support one file path (no glob)
  local included = line:match("^include (.+)")
  if not included then
    return {}
  end

  local path = vim.fn.simplify(dir_path .. "/" .. included)
  if not filelib.readable(path) then
    return {}
  end

  return M._load(path, dir_path, included_from)
end

function M.collect(source_ctx)
  local path = source_ctx.cwd .. "/Makefile"
  local dir_path = vim.fn.fnamemodify(path, ":h")
  local paths = vim.fn.glob(dir_path .. "/*.mk", false, true)

  local items = {}
  for _, p in ipairs(vim.list_extend({ path }, paths)) do
    items = vim.list_extend(items, M._load(p, source_ctx.cwd))
  end
  return items
end

vim.api.nvim_set_hl(0, "ThettoMakeTargetPath", { default = true, link = "Comment" })

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "ThettoMakeTargetPath",
    end_key = "value",
  },
})

M.kind_name = "cmd/make/target"

M.behaviors = {
  cwd = require("thetto2.util.cwd").upward({ "Makefile" }),
}

M.consumer_opts = {
  ui = { insert = false },
}

return M
