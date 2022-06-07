local M = {}
M.__index = M

function M.new(observer, work_callback, to_next)
  local finished = false
  local count = 0
  local work = vim.loop.new_work(work_callback, function(...)
    observer:next(to_next(...))
    count = count - 1
    if finished and count == 0 then
      observer:complete()
    end
  end)

  local tbl = {
    queue = function(_, ...)
      count = count + 1
      work:queue(...)
    end,
    complete = function()
      finished = true
      if count == 0 then
        observer:complete()
      end
    end,
  }
  return tbl
end

return M
