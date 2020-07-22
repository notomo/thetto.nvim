local M = {}

M.opts = {checkout = {track = false}}

M.action_checkout = function(self, items)
  local item = items[1]
  if item == nil then
    return
  end

  local cmd = {"git", "checkout"}
  if self.action_opts["track"] then
    table.insert(cmd, "-t")
  end
  table.insert(cmd, item.value)

  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      vim.api.nvim_out_write(job_self.all_output .. "\n")
    end,
  })
  job:start()
end

M.default_action = "checkout"

return M
