local M = {}

function M.collect(self, source_ctx)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)

  local pattern = source_ctx.pattern
  if pattern == nil or pattern == "" then
    local items = vim.tbl_map(function(line)
      return { value = line }
    end, lines)
    if source_ctx.interactive then
      self:append(items)
    end
    return items, nil, self.errors.skip_empty_pattern
  end

  local job = self.jobs.new({ "jq", pattern }, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end
      local items = vim.tbl_map(function(output)
        return { value = output }
      end, job_self:get_stdout())
      self:append(items)
    end,
    on_stderr = function(job_self)
      local items = vim.tbl_map(function(output)
        return { value = output, is_error = true }
      end, job_self:get_stderr())
      if #items == 0 then
        return
      end
      self:reset()
      self:append(items)
    end,
  })
  local err = job:start()
  if err ~= nil then
    return nil, nil, err
  end

  job.stdin:write(lines, function()
    if not job.stdin:is_closing() then
      job.stdin:close()
    end
  end)

  return {}, job
end

vim.cmd("highlight default link ThettoJqError WarningMsg")

function M.highlight(self, bufnr, first_line, items)
  local highlighter = self.highlights:create(bufnr)
  highlighter:filter("ThettoJqError", first_line, items, function(item)
    return item.is_error
  end)
end

M.kind_name = "word"

return M
