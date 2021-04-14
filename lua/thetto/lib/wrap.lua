local vim = vim

local M = {}

function M.debounce(ms, f)
  local timer = nil
  return function(...)
    if timer == nil then
      timer = vim.loop.new_timer()
    end
    timer:stop()
    local args = {...}
    timer:start(ms, 0, vim.schedule_wrap(function()
      f(unpack(args))
    end))
  end
end

function M.traceback(f)
  local ok, result, err = xpcall(f, debug.traceback)
  if not ok then
    error(result)
  end
  return result, err
end

return M
