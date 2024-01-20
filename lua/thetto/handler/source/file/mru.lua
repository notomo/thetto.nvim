local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")
local listlib = require("thetto.lib.list")
local vim = vim

local M = {}

M.opts = {
  cwd_marker = "%s/",
}

function M.collect(source_ctx)
  local paths = require("thetto.core.store").get_data("file/mru")
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

      if not filelib.readable(name) then
        return
      end

      return name
    end)
    :totable()
  vim.list_extend(paths, buffer_paths)
  paths = listlib.unique(paths)

  local to_relative = pathlib.relative_modifier(source_ctx.cwd)
  local dir = vim.fn.fnamemodify(source_ctx.cwd, ":t")
  local cwd_marker = source_ctx.opts.cwd_marker:format(dir)
  local home = pathlib.home()

  return vim
    .iter(paths)
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
