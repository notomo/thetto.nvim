local vim = vim

local M = {}

function M.promise(ms, f)
  local timer = assert(vim.uv.new_timer())
  local factory = function(...)
    timer:stop()

    local args = { ... }
    local promise, resolve = require("thetto.vendor.promise").with_resolvers()

    timer:start(
      ms,
      0,
      vim.schedule_wrap(function()
        resolve(f(unpack(args)))
      end)
    )

    return promise
  end
  local close = function()
    timer:close()
  end
  return factory, close
end

function M.wrap(ms, f)
  local timer = assert(vim.uv.new_timer())
  return function(...)
    timer:stop()

    local args = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      f(unpack(args))
    end)
  end, function()
    timer:stop()
  end
end

return M
