local M = {}

function M.collect(source_ctx)
  local source = require("thetto.util.source").by_name("git/log", {
    opts = {
      args = { "--follow" },
      path = vim.api.nvim_buf_get_name(source_ctx.bufnr),
    },
  })
  local new_source_ctx = vim.tbl_deep_extend("force", source_ctx, { opts = source.opts })
  return source.collect(new_source_ctx)
end

M.highlight = require("thetto.handler.source.git.log").highlight
M.kind_name = require("thetto.handler.source.git.log").kind_name

M.cwd = require("thetto.util.cwd").project()

M.consumer_opts = {
  ui = { insert = false },
}

return M
