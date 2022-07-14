local M = {}

M.opts = {
  max_depth = 10,
  to_absolute = function(_, path)
    return path
  end,
  modify_path = function(path)
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

  local to_items = function(cwd, data)
    local items = {}
    local paths = require("thetto.lib.job").parse_output(data)
    for _, path in ipairs(paths) do
      if path == "" or path == cwd then
        goto continue
      end
      local relative_path = require("thetto.lib.path").to_relative(path, cwd)
      table.insert(items, {
        value = relative_path,
        path = path,
      })
      ::continue::
    end
    return vim.mpack.encode(items)
  end

  return function(observer)
    local to_absolute = self.opts.to_absolute
    local output_buffer = require("thetto.util.job.output_buffer").new()
    local work_observer = require("thetto.util.job.work_observer").new(observer, to_items, function(encoded)
      local items = vim.mpack.decode(encoded)
      return vim.tbl_map(function(item)
        local value = self.opts.modify_path(item.value)
        return {
          value = value,
          path = to_absolute(source_ctx.cwd, item.path),
        }
      end, items)
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
      on_exit = function()
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

M.kind_name = "file"

return M
