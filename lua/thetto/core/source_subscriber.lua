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

  return function(observer)
    subscriber({
      next = function(o, ...)
        observer.next(o, source_filter(...))
      end,
      error = observer.error,
      complete = observer.complete,
      closed = observer.closed,
    })
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
          observer:complete(resolved)
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
