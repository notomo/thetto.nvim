local M = {}

function M.collect(source_ctx)
  return require("thetto.handler.source.git.log").collect(source_ctx:change_opts({
    args = { "--follow" },
    paths = { vim.api.nvim_buf_get_name(source_ctx.bufnr) },
  }))
end

M.highlight = require("thetto.handler.source.git.log").highlight
M.kind_name = require("thetto.handler.source.git.log").kind_name

return M
