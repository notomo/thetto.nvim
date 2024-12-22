local M = {}

function M.with_last(ms, f)
  local last_ms = vim.uv.now() - (ms + 1)
  local timer = assert(vim.uv.new_timer())

  local factory = function(...)
    timer:stop()

    local now = vim.uv.now()
    local elapsed_ms = now - last_ms
    last_ms = now

    local args = { ... }

    if elapsed_ms < ms then
      timer:start(ms - elapsed_ms, 0, function()
        f(unpack(args))
      end)
      return
    end

    f(unpack(args))
  end

  local cancel = function()
    local due = timer:get_due_in()
    timer:stop()
    return due > 0
  end

  local close = function()
    timer:close()
  end

  return factory, cancel, close
end
return M
