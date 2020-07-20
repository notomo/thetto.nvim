local jobs = require "thetto/job"

local M = {}

M.make = function(_, list)
  local job = jobs.new({"env"}, {
    on_exit = function(self)
      local items = {}
      for _, output in ipairs(self:get_stdout()) do
        table.insert(items, {value = output})
      end
      list.set(items)
    end,
  })
  return {}, job
end

M.kind_name = "word"

return M
