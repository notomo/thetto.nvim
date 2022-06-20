local M = {}

function M.action_remove(self, items)
  local ids = vim.tbl_map(function(item)
    return item.container_id
  end, items)
  local cmd = { "docker", "rm" }
  vim.list_extend(cmd, ids)
  local job = self.jobs.new(cmd, { on_exit = self.jobs.print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

return M
