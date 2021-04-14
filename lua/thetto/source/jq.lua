local M = {}

function M.collect(self, opts)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)

  local pattern = opts.pattern
  if pattern == nil or pattern == "" then
    local items = vim.tbl_map(function(line)
      return {value = line}
    end, lines)
    if opts.interactive then
      self:append(items, {items = items})
    end
    return items, nil, self.errors.skip_empty_pattern
  end

  local job = self.jobs.new({"jq", pattern}, {
    on_exit = function(job_self, code)
      if code ~= 0 then
        return
      end
      local items = vim.tbl_map(function(output)
        return {value = output}
      end, job_self:get_stdout())
      self:append(items, {items = items})
    end,
    on_stderr = function(job_self)
      local items = vim.tbl_map(function(output)
        return {value = output, is_error = true}
      end, job_self:get_stderr())
      if #items == 0 then
        return
      end
      vim.list_extend(items, self.ctx.items)
      self:reset()
      self:append(items)
    end,
  })
  local err = job:start()
  if err ~= nil then
    return nil, nil, err
  end

  job.stdin:write(table.concat(lines, "\n"))
  job.stdin:close()

  return {}, job
end

vim.cmd("highlight default link ThettoJqError WarningMsg")

function M.highlight(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  highlighter:filter("ThettoJqError", items, function(item)
    return item.is_error
  end)
end

M.kind_name = "word"

return M
