local M = {}

function M.immediate(action_name)
  return function(consumer_ctx)
    return require("thetto2.handler.consumer.immediate").new(consumer_ctx, action_name)
  end
end

return M
