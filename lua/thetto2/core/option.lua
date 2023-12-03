local M = {}

local default_start_opts = {
  pipeline_factory = function()
    return {
      filters = {},
      apply = function(_, items)
        return items
      end,
    }
  end,
  consumer_factory = function(pipeline, on_change, on_discard)
    return require("thetto2.handler.consumer.ui").new(pipeline.filters, on_change, on_discard)
  end,
  kind = {},
}
function M.new_start_opts(raw_opts)
  return vim.tbl_extend("force", default_start_opts, raw_opts or {})
end

return M
