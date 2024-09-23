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

function M.collect(source_ctx)
  local cmd = source_ctx.opts.get_command(source_ctx.cwd, source_ctx.opts.max_depth)

  local to_items = function(cwd, data)
    local paths = require("thetto.util.job.parse").output(data)
    local items = vim
      .iter(paths)
      :map(function(path)
        if path == "" or path == cwd then
          return
        end
        local relative_path = require("thetto.lib.path").to_relative(path, cwd)
        return {
          value = relative_path,
          path = path,
        }
      end)
      :totable()
    return vim.mpack.encode(items)
  end

  return function(observer)
    local to_absolute = source_ctx.opts.to_absolute
    local output_buffer = require("thetto.vendor.misclib.job.output").new_buffer()
    local work_observer = require("thetto.util.job.work_observer").new(observer, to_items, function(encoded)
      local items = vim.mpack.decode(encoded)
      return vim
        .iter(items)
        :map(function(item)
          local value = source_ctx.opts.modify_path(item.value)
          return {
            value = value,
            path = to_absolute(source_ctx.cwd, item.path),
          }
        end)
        :totable()
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
      on_exit = function()
        work_observer:complete()
      end,
      on_stderr = function()
        -- workaround to ignore permission error
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

M.kind_name = "file"

return M
