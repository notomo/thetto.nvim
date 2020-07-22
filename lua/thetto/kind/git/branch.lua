local M = {}

M.action_checkout = function(self, items)
  local item = items[1]
  if item == nil then
    return
  end
  local cmd = {"git", "checkout", item.value}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      vim.api.nvim_out_write(job_self.all_output .. "\n")
    end,
  })
  job:start()
end

M.action_default = M.action_checkout

return M
