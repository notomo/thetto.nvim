local pathlib = require("thetto.lib.path")
local vim = vim

local M = {}

M.opts = {
  max_depth = 10,
  to_absolute = function(_, path)
    return path
  end,
}

if vim.fn.has("win32") == 1 then
  M.opts.get_command = function(path, _)
    return { "where", "/R", path, "*" }
  end
else
  M.opts.get_command = function(path, max_depth)
    return {
      "find",
      "-L",
      path,
      "-maxdepth",
      max_depth,
      "-type",
      "d",
      "-name",
      ".git",
      "-prune",
      "-o",
      "-type",
      "f",
      "-print",
    }
  end
end

function M.collect(self, source_ctx)
  local cmd = self.opts.get_command(source_ctx.cwd, self.opts.max_depth)
  local to_relative = pathlib.relative_modifier(source_ctx.cwd)

  local items = {}
  local item_appender = self.jobs.loop(source_ctx.debounce_ms, function(co)
    for _ = 0, self.chunk_max_count do
      local ok, path = coroutine.resume(co)
      if not ok or path == nil then
        break
      end
      if path == "" or path == source_ctx.cwd then
        goto continue
      end

      local relative_path = self:_modify_path(to_relative(path))
      table.insert(items, { value = relative_path, path = self.opts.to_absolute(source_ctx.cwd, path) })
      ::continue::
    end
    self:append(items)
    items = {}
  end)

  local prev_last = nil
  local job = self.jobs.new(cmd, {
    on_stdout = function(job_self, _, data)
      if data == nil then
        return
      end

      -- HACk: outputs[#outputs] may be incompleted line
      -- ex. [{..., "/path/to/ho"}, {"ge/foo/bar", ...}]
      local outputs = job_self.parse_output(data)
      if prev_last ~= nil then
        outputs[1] = prev_last .. outputs[1]
        prev_last = nil
      end
      if not vim.endswith(data, "\n") then
        prev_last = outputs[#outputs]
        table.remove(outputs, #outputs)
      end

      item_appender(job_self, outputs)
    end,
    on_exit = function(_) end,
    stdout_buffered = false,
    stderr_buffered = false,
    cwd = source_ctx.cwd,
  })

  return {}, job
end

M.kind_name = "file"

function M._modify_path(_, path)
  return path
end

return M
