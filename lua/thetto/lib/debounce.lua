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

return M
