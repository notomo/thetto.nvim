local vim = vim
local setup = require("thetto/setup/file/mru")

local M = {}

M.collect = function(self)
  local items = {}

  local paths = setup.get()
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
  paths = self.listlib.unique(paths)

  local home = self.pathlib.home()
  for _, path in ipairs(vim.tbl_filter(setup.validate_fn(), paths)) do
    local value = path:gsub(home, "~")
    table.insert(items, {value = value, path = path})
  end
  return items
end

M.kind_name = "file"

return M
