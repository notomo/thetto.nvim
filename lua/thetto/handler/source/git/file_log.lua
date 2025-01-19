local M = {}

M.opts = {
  commit_hash = nil,
  path = nil,
}

function M.collect(source_ctx)
  local args = {}
  if source_ctx.opts.commit_hash then
    table.insert(args, source_ctx.opts.commit_hash)
  end
  table.insert(args, "--follow")

  local source = require("thetto.util.source").by_name("git/log", {
    opts = {
      args = args,
      path = source_ctx.opts.path or vim.api.nvim_buf_get_name(source_ctx.bufnr),
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
