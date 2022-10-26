local vim = vim

local M = {}

function M.debounce(ms, f)
  local timer = nil
  return function(...)
    if timer == nil then
      timer = vim.loop.new_timer()
    end
    timer:stop()
    local args = { ... }
    timer:start(
      ms,
      0,
      vim.schedule_wrap(function()
        f(unpack(args))
      end)
    )
  end
end

function M.debounce_promise(ms, f)
  local timer = nil
  return function(...)
    if timer == nil then
      timer = vim.loop.new_timer()
    end
    timer:stop()
    local args = { ... }
    return require("thetto.vendor.promise").new(function(resolve)
      timer:start(
        ms,
        0,
        vim.schedule_wrap(function()
          resolve(f(unpack(args)))
        end)
      )
    end)
  end
end

function M.throttle_with_last(ms, f)
  local last_ms = vim.loop.now() - ms
  local timer = vim.loop.new_timer()
  return function(...)
    timer:stop()

    local now = vim.loop.now()
    local elapsed_ms = now - last_ms
    last_ms = now

    local args = { ... }

    if elapsed_ms < ms then
      timer:start(
        ms,
        0,
        vim.schedule_wrap(function()
          f(unpack(args))
        end)
      )
      return
    end

    vim.schedule(function()
      f(unpack(args))
    end)
  end
end

return M
