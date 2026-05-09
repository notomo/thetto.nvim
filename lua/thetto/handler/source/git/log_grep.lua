local M = {}

function M.get_pattern()
  return vim.fn.input("Pattern: ")
end

function M.collect(source_ctx)
  local pattern = source_ctx.pattern
  if pattern == "" then
    return {}
  end

  local source = require("thetto.util.source").by_name("git/log", {
    opts = {
      args = { "-G", pattern },
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

M.modify_pipeline = require("thetto.util.pipeline").prepend({
  require("thetto.util.filter").by_name("source_input"),
})

return M
