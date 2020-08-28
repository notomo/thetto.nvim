local M = {}

M.opts = {ignore = {}}

M.collect = function(self, opts)
  local file_path = vim.api.nvim_buf_get_name(0)
  if vim.fn.filereadable(file_path) ~= 1 then
    return {}, nil
  end

  local cmd = {"ctags", "--output-format=xref", "-f", "-", file_path}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        local value, typ, row, path, line = output:match("(%S+)%s+(%S+)%s+(%d+)%s+(%S+)%s+(.+)")
        if vim.tbl_contains(self.opts.ignore, typ) then
          goto continue
        end
        local _desc = ("%s [%s]"):format(value, typ)
        local desc = ("%s %s"):format(_desc, line)
        table.insert(items, {
          desc = desc,
          value = value,
          path = path,
          row = tonumber(row),
          column_offsets = {value = 0, line = #_desc, type = #value + 1},
        })
        ::continue::
      end
      self.append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })

  return {}, job
end

M.highlight = function(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  for i, item in ipairs(items) do
    highlighter:add("Comment", i - 1, item.column_offsets.line, -1)
    highlighter:add("Statement", i - 1, item.column_offsets.type, item.column_offsets.line)
  end
end

M.kind_name = "file"

M.sorters = {"row"}

return M
