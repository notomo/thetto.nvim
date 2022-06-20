local M = {}

function M.action_remove(self, items)
  local ids = vim.tbl_map(function(item)
    return item.image_id
  end, items)
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  local job = self.jobs.new(cmd, { on_exit = self.jobs.print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

function M.action_untag(self, items)
  local ids = vim.tbl_map(function(item)
    return item.value
  end, items)
  local cmd = { "docker", "rmi" }
  vim.list_extend(cmd, ids)
  local job = self.jobs.new(cmd, { on_exit = self.jobs.print_output })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

return M
