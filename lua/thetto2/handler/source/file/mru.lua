local pathlib = require("thetto2.lib.path")
local listlib = require("thetto2.lib.list")
local Store = require("thetto2.core.store")
local vim = vim

local M = {}

M.opts = {
  cwd_marker = "%s/",
}

function M.collect(source_ctx)
  local store, err = Store.new_or_get("file/mru")
  if err ~= nil then
    return nil, err
  end

  local paths = store.data()
  local buffer_paths = vim
    .iter(vim.fn.range(vim.fn.bufnr("$"), 1, -1))
    :map(function(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      local name = vim.api.nvim_buf_get_name(bufnr)
      if name == "" then
        return
      end

      return name
    end)
    :totable()
  vim.list_extend(paths, buffer_paths)
  vim.list_extend(paths, vim.v.oldfiles)
  paths = listlib.unique(paths)

  local to_relative = pathlib.relative_modifier(source_ctx.cwd)
  local dir = vim.fn.fnamemodify(source_ctx.cwd, ":t")
  local cwd_marker = source_ctx.opts.cwd_marker:format(dir)
  local home = pathlib.home()

  return vim
    .iter(paths)
    :filter(function(path)
      return store.validate(path)
    end)
    :map(function(path)
      local relative_path = to_relative(path)
      local value = relative_path:gsub(home, "~")
      if path ~= relative_path then
        value = cwd_marker .. relative_path
      end
      return {
        value = value,
        path = path,
      }
    end)
    :totable()
end

M.kind_name = "file"

return M
