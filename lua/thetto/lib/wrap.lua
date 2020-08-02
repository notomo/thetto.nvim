local M = {}

M.debounce = function(ms, f)
  local timer = nil
  return function()
    if timer == nil then
      timer = vim.loop.new_timer()
    end
    timer:stop()
    timer:start(ms, 0, vim.schedule_wrap(f))
  end
end

M.traceback = function(f)
  local ok, result, err = xpcall(f, debug.traceback)
  if not ok then
    error(result)
  end
  return result, err
end

return M
