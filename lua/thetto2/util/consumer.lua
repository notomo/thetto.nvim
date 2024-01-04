local M = {}

function M.ui()
  return function(consumer_ctx, pipeline, callbacks)
    return require("thetto2.handler.consumer.ui").new(consumer_ctx, pipeline:filters(), callbacks, true)
  end
end

function M.immediate(action_name)
  return function(consumer_ctx, _, callbacks)
    return require("thetto2.handler.consumer.immediate").new(consumer_ctx, action_name, callbacks)
  end
end

return M
