local M = {}

function M.ui(raw_opts)
  raw_opts = raw_opts or {}
  return function(consumer_ctx, source, pipeline, callbacks, actions)
    local kind = require("thetto2.core.kind").by_name(source.kind_name or "base", actions)
    if raw_opts.has_sidecar == nil then
      raw_opts.has_sidecar = require("thetto2.core.kind").can_preview(kind)
    end

    local opts_from_source = vim.tbl_get(source, "consumer_opts", "ui") or {}
    raw_opts = vim.tbl_deep_extend("force", raw_opts, opts_from_source)

    return require("thetto2.handler.consumer.ui").new(consumer_ctx, source, pipeline, callbacks, actions, raw_opts)
  end
end

function M.immediate(raw_opts)
  raw_opts = raw_opts or {}
  return function(consumer_ctx, _, _, callbacks)
    return require("thetto2.handler.consumer.immediate").new(consumer_ctx, callbacks, raw_opts)
  end
end

return M
