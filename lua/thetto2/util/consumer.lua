local M = {}

function M.immediate()
  return function(consumer_ctx)
    return require("thetto2.handler.consumer.immediate").new(consumer_ctx)
  end
end

return M
