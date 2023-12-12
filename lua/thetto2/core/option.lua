local M = {}

local default_start_opts = {
  pipeline_factory = function()
    return require("thetto2.core.pipeline").new({
      require("thetto2.handler.pipeline.filter.substring"),
    })
  end,
  consumer_factory = function(pipeline, ctx_key, callbacks)
    return require("thetto2.handler.consumer.ui").new(pipeline:filters(), ctx_key, callbacks)
  end,
  kind = {},
}
function M.new_start_opts(raw_opts)
  return vim.tbl_extend("force", default_start_opts, raw_opts or {})
end

return M
