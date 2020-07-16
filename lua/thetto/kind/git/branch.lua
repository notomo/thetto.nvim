local jobs = require "thetto/job"

local M = {}

M.action_checkout = function(items)
  local item = items[1]
  if item == nil then
    return
  end
  local cmd = {"git", "checkout", item.value}
  local job = jobs.new(cmd, {
    on_exit = function(self)
      vim.api.nvim_out_write(self.all_output .. "\n")
    end,
  })
  job:start()
end

M.action_default = M.action_checkout

return M
