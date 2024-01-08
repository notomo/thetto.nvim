local M = {}

function M.collect(source_ctx)
  return require("thetto2.handler.source.git.log").collect(source_ctx:change_opts({
    args = { "--follow" },
    path = vim.api.nvim_buf_get_name(source_ctx.bufnr),
  }))
end

M.highlight = require("thetto2.handler.source.git.log").highlight
M.kind_name = require("thetto2.handler.source.git.log").kind_name

M.behaviors = {
  cwd = require("thetto2.util.cwd").project(),
}

M.consumer_opts = {
  ui = { insert = false },
}

return M
