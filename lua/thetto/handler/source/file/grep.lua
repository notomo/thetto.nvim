local M = {}

M.opts = {
  command = "grep",
  pattern_opt = "-e",
  command_opts = { "-inH" },
  recursive_opt = "-r",
  separator = "--",
}

function M.collect(self, opts)
  local pattern = opts.pattern
  if not opts.interactive and pattern == nil then
    pattern = vim.fn.input("Pattern: ")
  end
  if pattern == nil or pattern == "" then
    if opts.interactive then
      self:append({})
    end
    return {}, nil, self.errors.skip_empty_pattern
  end

  local paths = opts.cwd
  local cmd = vim.list_extend({ self.opts.command }, self.opts.command_opts)
  for _, x in ipairs({
    self.opts.recursive_opt,
    self.opts.pattern_opt,
    pattern,
    self.opts.separator,
    paths,
  }) do
    if x == "" then
      goto continue
    end
    table.insert(cmd, x)
    ::continue::
  end

  local to_relative = self.pathlib.relative_modifier(opts.cwd)

  local items = {}
  local item_appender = self.jobs.loop(opts.debounce_ms, function(co)
    for _ = 0, self.chunk_max_count do
      local ok, output = coroutine.resume(co)
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
        column_offsets = { ["path:relative"] = 0, value = #label + 1 },
      })
      ::continue::
    end
    self:append(items)
    items = {}
  end)

  local job = self.jobs.new(cmd, {
    on_stdout = function(job_self, _, data)
      local outputs = job_self.parse_output(data)
      item_appender(job_self, outputs)
    end,
    on_exit = function(_) end,
    stdout_buffered = false,
    stderr_buffered = false,
    cwd = opts.cwd,
  })

  return {}, job
end

vim.cmd("highlight default link ThettoFileGrepPath Comment")
vim.cmd("highlight default link ThettoFileGrepMatch Define")

-- NOTICE: support only this pattern
local highlight_target = vim.regex("\\v[[:alnum:]_]+")

function M.highlight(self, bufnr, first_line, items, source_ctx)
  local highlighter = self.highlights:create(bufnr)
  local pattern = (source_ctx.pattern or ""):lower()
  local ok = ({ highlight_target:match_str(pattern) })[1] ~= nil
  for i, item in ipairs(items) do
    highlighter:add("ThettoFileGrepPath", first_line + i - 1, 0, item.column_offsets.value - 1)
    if ok then
      -- NOTICE: support only ignorecase
      -- NOTICE: support only the first occurrence
      local s, e = (item.value:lower()):find(pattern, 1, true)
      if s ~= nil then
        highlighter:add(
          "ThettoFileGrepMatch",
          first_line + i - 1,
          item.column_offsets.value + s - 1,
          item.column_offsets.value + e
        )
      end
    end
  end
end

M.kind_name = "file"
M.color_label_key = "path"

return M
