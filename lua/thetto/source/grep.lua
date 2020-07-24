local M = {}

local parse_line = function(line)
  local path_row = line:match(".*:%d+:")
  if not path_row then
    return
  end
  local path, row = unpack(vim.split(path_row, ":", true))
  local matched_line = line:sub(#path_row + 1)
  return path, tonumber(row), matched_line
end

M.command = "grep"
M.pattern_opt = "-e"
M.opts = {"-inH"}
M.recursive_opt = "-r"
M.separator = "--"

M.collect = function(self, opts)
  local pattern = opts.pattern or vim.fn.input("Pattern: ")
  if pattern == "" then
    return {}, nil
  end

  local paths = opts.cwd
  local cmd = vim.list_extend({M.command}, M.opts)
  for _, x in ipairs({M.recursive_opt, M.pattern_opt, pattern, M.separator, paths}) do
    if x == "" then
      goto continue
    end
    table.insert(cmd, x)
    ::continue::
  end

  local buffered_items = {}
  local job = self.jobs.new(cmd, {
    on_stdout = function(job_self, _, data)
      if data == nil then
        return
      end

      local outputs = job_self.parse_output(data)
      for _, output in ipairs(outputs) do
        local path, row, matched_line = parse_line(output)
        if path == nil then
          goto continue
        end
        local relative_path = path:gsub("^" .. opts.cwd .. "/", "")
        local label = ("%s:%d"):format(relative_path, row)
        local desc = ("%s %s"):format(label, matched_line)
        table.insert(buffered_items, {
          desc = desc,
          value = matched_line,
          path = path,
          row = row,
          _label_length = #label,
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

M.highlight = function(self, bufnr, items)
  local ns = self.highlights.reset(bufnr)
  for i, item in ipairs(items) do
    vim.api.nvim_buf_add_highlight(bufnr, ns, "Comment", i - 1, 0, item._label_length)
  end
end

M.kind_name = "file/position"

return M
