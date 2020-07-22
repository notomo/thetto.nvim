local util = require "thetto/util"

local M = {}

M.ignore_pattern = "^$"

M.collect = function()
  local items = {}

  local paths = {}
  for _, bufnr in ipairs(vim.fn.range(vim.fn.bufnr("$"), 1, -1)) do
    if not vim.api.nvim_buf_is_valid(bufnr) then
      goto continue
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
      goto continue
    end

    table.insert(paths, vim.api.nvim_buf_get_name(bufnr))
    ::continue::
  end

  vim.list_extend(paths, vim.v.oldfiles)
  paths = util.unique(paths)

  local home = os.getenv("HOME")
  local regex = vim.regex(M.ignore_pattern)
  for _, path in ipairs(paths) do
    if regex:match_str(path) then
      goto continue
    end
    local desc = path:gsub(home, "~")
    table.insert(items, {desc = desc, value = path, path = path})
    ::continue::
  end
  return items
end

M.kind_name = "file"

return M
