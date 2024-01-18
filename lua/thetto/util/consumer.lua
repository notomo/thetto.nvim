local M = {}

function M.ui(raw_opts)
  raw_opts = raw_opts or {}
  return function(consumer_ctx, source, pipeline, callbacks, actions)
    local opts_from_source = vim.tbl_get(source, "consumer_opts", "ui") or {}
    local opts = vim.tbl_deep_extend("force", raw_opts, opts_from_source)

    local kind = require("thetto.core.kind").by_name(source.kind_name or "base", actions)
    if opts.has_sidecar == nil then
      opts.has_sidecar = require("thetto.core.kind").can_preview(kind)
    end

    return require("thetto.handler.consumer.ui").new(consumer_ctx, source, pipeline, callbacks, actions, opts)
  end
end

function M.immediate(raw_opts)
  raw_opts = raw_opts or {}
  return function(consumer_ctx, _, _, callbacks, actions)
    return require("thetto.handler.consumer.immediate").new(consumer_ctx, callbacks, actions, raw_opts)
  end
end

return M
