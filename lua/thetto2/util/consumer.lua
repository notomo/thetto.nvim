local M = {}

function M.ui(raw_opts)
  raw_opts = raw_opts or {}
  return function(consumer_ctx, source, pipeline, callbacks)
    local kind = require("thetto2.core.kind").by_name(source.kind_name or "base")
    if raw_opts.has_sidecar == nil then
      raw_opts.has_sidecar = kind:can_preview()
    end
    return require("thetto2.handler.consumer.ui").new(consumer_ctx, source, pipeline, callbacks, raw_opts)
  end
end

function M.immediate(raw_opts)
  raw_opts = raw_opts or {}
  return function(consumer_ctx, _, _, callbacks)
    return require("thetto2.handler.consumer.immediate").new(consumer_ctx, callbacks, raw_opts)
  end
end

return M
