local M = {}

function M.wrap(ms, f)
  local timer
  return function(...)
    if timer and not timer:is_closing() then
      timer:close()
    end
    local args = { ... }
    timer = vim.uv.new_timer()
    timer:start(ms, 0, function()
      if not timer:is_closing() then
        timer:close()
      end
      f(unpack(args))
    end)
  end
end

return M
