local vim = vim

local M = {}

function M.promise(ms, f)
  local timer = nil
  return function(...)
    if not timer then
      timer = vim.uv.new_timer()
    end
    ---@diagnostic disable-next-line: need-check-nil
    timer:stop()

    local args = { ... }
    local promise, resolve = require("thetto.vendor.promise").with_resolvers()

    ---@diagnostic disable-next-line: need-check-nil
    timer:start(
      ms,
      0,
      vim.schedule_wrap(function()
        resolve(f(unpack(args)))
      end)
    )

    return promise
  end
end

return M
