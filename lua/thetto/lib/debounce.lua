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
    return require("thetto.vendor.promise").new(function(resolve)
      ---@diagnostic disable-next-line: need-check-nil
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

return M
