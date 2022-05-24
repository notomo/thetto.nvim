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
      local is_error = code ~= 0
      local items = vim.tbl_map(function(output)
        return { value = output, is_error = is_error }
      end, job_self:get_output())
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

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "ThettoJqError",
    filter = function(item)
      return item.is_error
    end,
  },
})

M.kind_name = "word"

return M
