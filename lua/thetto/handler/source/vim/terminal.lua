local pathlib = require("thetto.lib.path")
local vim = vim

local M = {}

function M.collect(source_ctx)
  local dir = vim.fs.basename(source_ctx.cwd)
  local home = pathlib.home()

  return vim
    .iter(vim.api.nvim_list_bufs())
    :map(function(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      if vim.bo[bufnr].buftype ~= "terminal" then
        return
      end

      local name = vim.api.nvim_buf_get_name(bufnr)
      local value = name:gsub("~", home)
      value = value:gsub("^term://", "")
      value = value:gsub(vim.pesc(source_ctx.cwd), dir)

      return {
        value = value,
        bufnr = bufnr,
      }
    end)
    :totable()
end

M.kind_name = "vim/buffer"

return M
