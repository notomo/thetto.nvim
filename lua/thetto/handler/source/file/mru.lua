local pathlib = require("thetto.lib.path")
local listlib = require("thetto.lib.list")
local Store = require("thetto.core.store").Store
local vim = vim

local M = {}

M.opts = { cwd_marker = "%s/" }

function M.collect(self, source_ctx)
  local store, err = Store.new_or_get("file/mru")
  if err ~= nil then
    return nil, nil, err
  end

  local paths = store:data()
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
  paths = listlib.unique(paths)

  local to_relative = pathlib.relative_modifier(source_ctx.cwd)
  local dir = vim.fn.fnamemodify(source_ctx.cwd, ":t")
  local cwd_marker = self.opts.cwd_marker:format(dir)
  local home = pathlib.home()

  local items = {}
  for _, path in ipairs(vim.tbl_filter(store:validator(), paths)) do
    local relative_path = to_relative(path)
    local value = relative_path:gsub(home, "~")
    local item = { value = value, path = path }
    if path ~= relative_path then
      item.value = cwd_marker .. relative_path
    end
    table.insert(items, item)
  end
  return items
end

M.kind_name = "file"

return M
