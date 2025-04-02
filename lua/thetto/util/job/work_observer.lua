local M = {}

local bulk_size = 50

function M.new(cwd, observer, work_callback, to_next, optional_arg)
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

  local concat = require("thetto.util.job.parse").concat_func()
  return {
    queue = function(_, str)
      count = count + 1
      local lined_str = concat(str)
      bulk = bulk .. lined_str
      if (count % bulk_size) == 0 then
        work:queue(cwd, bulk, optional_arg)
        bulk = ""
      end
    end,
    complete = function()
      finished = true
      local lined_str = concat("")
      bulk = bulk .. lined_str
      work:queue(cwd, bulk, optional_arg)
      if count <= 0 then
        observer:complete()
      end
    end,
  }
end

return M
