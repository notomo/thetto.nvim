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

return M
