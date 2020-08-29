local M = {}

M.command = "grep"
M.pattern_opt = "-e"
M.command_opts = {"-inH"}
M.recursive_opt = "-r"
M.separator = "--"

M.collect = function(self, opts)
  local pattern = opts.pattern or vim.fn.input("Pattern: ")
  if pattern == "" then
    return {}, nil
  end

  local paths = opts.cwd
  local cmd = vim.list_extend({M.command}, M.command_opts)
  for _, x in ipairs({M.recursive_opt, M.pattern_opt, pattern, M.separator, paths}) do
    if x == "" then
      goto continue
    end
    table.insert(cmd, x)
    ::continue::
  end

  local to_relative = self.pathlib.relative_modifier(opts.cwd)
  local buffered_items = {}
  local job = self.jobs.new(cmd, {
    on_stdout = function(job_self, _, data)
      if data == nil then
        return
      end

      local outputs = job_self.parse_output(data)
      for _, output in ipairs(outputs) do
        local path, row, matched_line = self.pathlib.parse_with_row(output)
        if path == nil then
          goto continue
        end
        local relative_path = to_relative(path)
        local label = ("%s:%d"):format(relative_path, row)
        local desc = ("%s %s"):format(label, matched_line)
        table.insert(buffered_items, {
          desc = desc,
          value = matched_line,
          path = path,
          row = row,
          column_offsets = {value = #label + 1},
        })
        ::continue::
      end
    end,
    on_exit = function(_)
      self.append(buffered_items)
      buffered_items = {}
    end,
    on_interval = function(_)
      self.append(buffered_items)
      buffered_items = {}
    end,
    stdout_buffered = false,
    stderr_buffered = false,
    cwd = opts.cwd,
  })

  return {}, job
end

vim.api.nvim_command("highlight default link ThettoFileGrepPath Comment")

M.highlight = function(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  for i, item in ipairs(items) do
    highlighter:add("ThettoFileGrepPath", i - 1, 0, item.column_offsets.value - 1)
  end
end

M.kind_name = "file"
M.color_label_key = "path"

return M
