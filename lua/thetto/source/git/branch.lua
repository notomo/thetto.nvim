local jobs = require "thetto/job"

local M = {}

M.make = function(list)
  local job = jobs.new({"git", "branch", "--format", "%(refname:short)"}, {
    on_exit = function(self)
      local items = {}
      for _, output in ipairs(self:get_stdout()) do
        table.insert(items, {value = output})
      end
      list.update(items)
    end,
  })
  return {}, job
end

M.kind_name = "git/branch"

return M
