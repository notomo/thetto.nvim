local M = {}

local bulk_size = 50

function M.new(cwd, observer, work_callback, to_next)
  local finished = false
  local count = 0
  local bulk = ""

  local work = vim.uv.new_work(work_callback, function(...)
    observer:next(to_next(...))
    count = count - bulk_size
    if finished and count <= 0 then
      observer:complete()
    end
  end)

  return {
    queue = function(_, str)
      count = count + 1
      bulk = bulk .. str
      if (count % bulk_size) == 0 then
        work:queue(cwd, bulk)
        bulk = ""
      end
    end,
    complete = function()
      finished = true
      work:queue(cwd, bulk)
      if count <= 0 then
        observer:complete()
      end
    end,
  }
end

return M
