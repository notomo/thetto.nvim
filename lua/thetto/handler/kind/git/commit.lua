local M = {}

local start = function(source, bufnr, item)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"

  local cmd = { "git", "show", "--date=iso", item.commit_hash }

  local job = source.jobs.new(cmd, {
    on_exit = function(job_self)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local lines = job_self:get_output()
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end,
    on_stderr = source.jobs.print_stderr,
  })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

local open = function(source, items, f)
  for _, item in ipairs(items) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    local _, err = start(source, bufnr, item)
    if err then
      return nil, err
    end
    f(bufnr)
  end
end

function M.action_open(self, items)
  return open(self, items, function(bufnr)
    vim.cmd([[buffer ]] .. bufnr)
  end)
end

function M.action_vsplit_open(self, items)
  return open(self, items, function(bufnr)
    vim.cmd([[vsplit | buffer ]] .. bufnr)
  end)
end

function M.action_tab_open(self, items)
  return open(self, items, function(bufnr)
    vim.cmd([[tabedit | buffer ]] .. bufnr)
  end)
end

function M.action_preview(self, items, ctx)
  local item = items[1]
  if not item then
    return nil
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local job, err = start(self, bufnr, item)
  if err ~= nil then
    return nil, err
  end

  ctx.ui:open_preview(item, { raw_bufnr = bufnr })

  return job, nil
end

M.default_action = "open"

return M
