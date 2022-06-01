local M = {}

M.opts = {
  command = "grep",
  pattern_opt = "-e",
  command_opts = { "-inH" },
  recursive_opt = "-r",
  separator = "--",
}

function M.collect(self, source_ctx)
  local pattern = source_ctx.pattern
  if not source_ctx.interactive and pattern == nil then
    pattern = vim.fn.input("Pattern: ")
  end
  if pattern == nil or pattern == "" then
    return function(observer)
      observer:complete()
    end
  end

  local paths = source_ctx.cwd
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

  local to_items = function(cwd, data)
    local items = {}
    local outputs = require("thetto.lib.job").parse_output(data)
    for _, output in ipairs(outputs) do
      local path, row, matched_line = require("thetto.lib.path").parse_with_row(output)
      if not path then
        goto continue
      end
      local relative_path = require("thetto.lib.path").to_relative(path, cwd)
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
    return vim.mpack.encode(items)
  end

  return function(observer)
    local output_buffer = require("thetto.util").job.output_buffer()
    local work_observer = require("thetto.util").job.work_observer(observer, to_items, function(encoded)
      return vim.mpack.decode(encoded)
    end)
    local job = self.jobs.new(cmd, {
      on_stdout = function(_, _, data)
        if not data then
          work_observer:queue(source_ctx.cwd, output_buffer:pop())
          return
        end

        local str = output_buffer:append(data)
        if not str then
          return
        end

        work_observer:queue(source_ctx.cwd, str)
      end,
      on_exit = function(_)
        work_observer:complete()
      end,
      stdout_buffered = false,
      stderr_buffered = false,
      cwd = source_ctx.cwd,
    })

    local err = job:start()
    if err then
      return observer:error(err)
    end
  end
end

vim.api.nvim_set_hl(0, "ThettoFileGrepPath", { default = true, link = "Comment" })
vim.api.nvim_set_hl(0, "ThettoFileGrepMatch", { default = true, link = "Define" })

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
