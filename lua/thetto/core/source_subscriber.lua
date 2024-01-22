local M = {}

function M.new(source, source_ctx)
  local subscriber_or_items, source_err = source.collect(source_ctx)
  if source_err then
    local source_errored = true
    return function(observer)
      local msg = require("thetto.vendor.misclib.message").wrap(source_err)
      observer:error(msg)
    end,
      source_errored
  end

  if type(subscriber_or_items) == "function" then
    return subscriber_or_items
  end

  if type(subscriber_or_items.next) == "function" then
    -- promise case
    return function(observer)
      subscriber_or_items
        :next(function(result)
          if type(result) == "function" then
            -- promise returns subscriber case
            result(observer)
            return
          end

          -- promise returns items case
          observer:next(result)
          observer:complete(result)
        end)
        :catch(function(err)
          observer:error(err)
        end)
    end
  end

  return function(observer)
    observer:next(subscriber_or_items)
    observer:complete()
  end
end

return M
