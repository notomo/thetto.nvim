local M = {}

M.command = "grep"
M.pattern_opt = "-e"
M.command_opts = {"-inH"}
M.recursive_opt = "-r"
M.separator = "--"

M.chunk_max_count = 10000

M.collect = function(self, opts)
  local pattern = opts.pattern
  if not opts.interactive and pattern == nil then
    pattern = vim.fn.input("Pattern: ")
  end
  if pattern == nil or pattern == "" then
    if opts.interactive then
      self.append({})
    end
    return {}, nil, self.errors.skip_empty_pattern
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
  local current = nil
  local next_outputs = nil
  local timer = vim.loop.new_timer()
  local job = self.jobs.new(cmd, {
    on_stdout = function(job_self, _, data)
      if data == nil then
        return
      end

      local outputs = job_self.parse_output(data)
      if timer:is_active() then
        vim.list_extend(next_outputs or {}, outputs)
        return
      end
      current = coroutine.create(function()
        for _, o in ipairs(outputs) do
          coroutine.yield(o)
        end
      end)

      timer:start(0, opts.debounce_ms, vim.schedule_wrap(function()
        if job_self.discarded then
          return timer:stop()
        end

        local items = {}
        for _ = 0, M.chunk_max_count do
          local ok, output = coroutine.resume(current)
          if not ok or output == nil then
            break
          end

          local path, row, matched_line = self.pathlib.parse_with_row(output)
          if path == nil then
            goto continue
          end
          local relative_path = to_relative(path)
          local label = ("%s:%d"):format(relative_path, row)
          local desc = ("%s %s"):format(label, matched_line)
          table.insert(items, {
            desc = desc,
            value = matched_line,
            path = path,
            row = row,
            column_offsets = {["path:relative"] = 0, value = #label + 1},
          })
          ::continue::
        end
        self.append(items)

        if next_outputs == nil then
          timer:stop()
        else
          current = coroutine.create(function()
            for _, o in ipairs(next_outputs) do
              coroutine.yield(o)
            end
          end)
          next_outputs = nil
        end
      end))
    end,
    on_exit = function(_)
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
