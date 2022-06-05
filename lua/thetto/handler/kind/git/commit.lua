local M = {}

function M.action_preview(self, items, ctx)
  local item = items[1]
  if not item then
    return nil
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"

  local cmd = { "git", "show", "--date=iso", item.commit_hash }

  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local lines = job_self:get_output()
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end,
    on_stderr = self.jobs.print_stderr,
  })
  local err = job:start()
  if err ~= nil then
    return nil, err
  end

  ctx.ui:open_preview(item, { raw_bufnr = bufnr })
end

M.default_action = "show"

return M
