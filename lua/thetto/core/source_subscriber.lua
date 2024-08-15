local M = {}

function M.new(source, source_ctx)
  local result, source_err = source.collect(source_ctx)
  if source_err then
    local source_errored = true
    return function(observer)
      observer:error(source_err)
    end, source_errored
  end

  local subscriber = M._new(result)
  local source_filter = source.filter
  if not source_filter then
    return subscriber
  end

  local observable = require("thetto.vendor.misclib.observable").new(subscriber)
  return function(observer)
    local subscription = observable:subscribe({
      next = function(...)
        observer:next(source_filter(...))
      end,
      complete = function(...)
        observer:complete(...)
      end,
      error = function(...)
        observer:error(...)
      end,
    })
    return function()
      subscription:unsubscribe()
    end
  end
end

function M._new(result)
  if type(result) == "function" then
    local subscriber = result
    return subscriber
  end

  if type(result.next) == "function" then
    local promise = result
    return function(observer)
      promise
        :next(function(resolved)
          if type(resolved) == "function" then
            -- promise returns subscriber case
            resolved(observer)
            return
          end

          -- promise returns items case
          observer:next(resolved)
          observer:complete()
        end)
        :catch(function(err)
          observer:error(err)
        end)
    end
  end

  local items = result
  return function(observer)
    observer:next(items)
    observer:complete()
  end
end

return M
