local M = {}

M.opts = {
  command = "grep",
  pattern_opt = "-e",
  command_opts = { "-inH" },
  recursive_opt = "-r",
  separator = "--",
}

function M.get_pattern()
  return vim.fn.input("Pattern: ")
end

function M.collect(source_ctx)
  local pattern = source_ctx.pattern
  if pattern == "" then
    return {}
  end

  local cmd = { source_ctx.opts.command }
  vim.list_extend(cmd, source_ctx.opts.command_opts)
  vim.list_extend(cmd, {
    source_ctx.opts.recursive_opt,
    source_ctx.opts.pattern_opt,
    pattern,
    source_ctx.opts.separator,
    source_ctx.cwd,
  })
  cmd = vim
    .iter(cmd)
    :filter(function(x)
      return x ~= ""
    end)
    :totable()

  local to_items = function(cwd, data)
    local outputs = require("thetto.util.job.parse").output(data)
    local items = vim
      .iter(outputs)
      :map(function(output)
        local path, row, matched_line = require("thetto.lib.path").parse_with_row(output)
        if not path then
          return
        end
        local relative_path = require("thetto.lib.path").to_relative(path, cwd)
        local label = ("%s:%d"):format(relative_path, row)
        local desc = ("%s %s"):format(label, matched_line)
        return {
          desc = desc,
          value = matched_line,
          path = path,
          row = row,
          column_offsets = { ["path:relative"] = 0, value = #label + 1 },
        }
      end)
      :totable()
    return vim.mpack.encode(items)
  end

  return function(observer)
    local output_buffer = require("thetto.vendor.misclib.job.output").new_buffer()
    local work_observer = require("thetto.util.job.work_observer").new(observer, to_items, function(encoded)
      return vim.mpack.decode(encoded)
    end)
    local job = require("thetto.util.job").execute(cmd, {
      on_stdout = function(_, data)
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
      on_stderr = function()
        -- workaround to ignore regex parse error
      end,
      stdout_buffered = false,
      stderr_buffered = false,
      cwd = source_ctx.cwd,
    })
    if type(job) == "string" then
      local err = job
      return observer:error(err)
    end
    return vim.schedule_wrap(function()
      job:stop()
    end)
  end
end

vim.api.nvim_set_hl(0, "ThettoFileGrepPath", { default = true, link = "Comment" })
vim.api.nvim_set_hl(0, "ThettoFileGrepMatch", { default = true, link = "Define" })

-- NOTICE: support only this pattern
local highlight_target = vim.regex("\\v[[:alnum:]_]+")

local highlight_opts = {
  priority = vim.highlight.priorities.user - 1,
}

function M.highlight(decorator, items, first_line, source_ctx)
  local pattern = (source_ctx.pattern or ""):lower()
  local ok = ({ highlight_target:match_str(pattern) })[1] ~= nil
  for i, item in ipairs(items) do
    decorator:highlight("ThettoFileGrepPath", first_line + i - 1, 0, item.column_offsets.value - 1, highlight_opts)
    if ok then
      -- NOTICE: support only ignorecase
      -- NOTICE: support only the first occurrence
      local s, e = (item.value:lower()):find(pattern, 1, true)
      if s ~= nil then
        decorator:highlight(
          "ThettoFileGrepMatch",
          first_line + i - 1,
          item.column_offsets.value + s - 1,
          item.column_offsets.value + e,
          highlight_opts
        )
      end
    end
  end
end

M.kind_name = "file"

return M
