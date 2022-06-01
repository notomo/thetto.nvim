local jobs = require("thetto.lib.job")

local M = {}

function M.run(cmd, source_ctx, to_item, opts)
  local default_opts = {
    to_outputs = function(job)
      return job:get_stdout()
    end,
    stop_on_error = true,
    input = nil,
    cwd = source_ctx.cwd,
    stdout_buffered = true,
    stderr_buffered = true,
  }
  opts = vim.tbl_extend("force", default_opts, opts or {})

  return function(observer)
    local job = jobs.new(cmd, {
      on_exit = function(self, code)
        if opts.stop_on_error and code ~= 0 then
          return observer:error(self.stderr_output)
        end

        local items = {}
        for _, output in ipairs(opts.to_outputs(self)) do
          local item = to_item(output, code)
          if not item then
            goto continue
          end

          table.insert(items, item)

          ::continue::
        end
        observer:next(items)
        observer:complete()
      end,
      cwd = opts.cwd,
      stdout_buffered = opts.stdout_buffered,
      stderr_buffered = opts.stderr_buffered,
    })

    local err = job:start()
    if err then
      return observer:error(err)
    end

    if not opts.input then
      return
    end
    job.stdin:write(opts.input, function()
      if job.stdin:is_closing() then
        return
      end
      job.stdin:close()
    end)
  end
end

local OutputBuffer = {}
OutputBuffer.__index = OutputBuffer

function M.output_buffer()
  local tbl = { _incompleted = "" }
  return setmetatable(tbl, OutputBuffer)
end

function OutputBuffer.append(self, data)
  local head_index = data:find("\n")
  if not head_index then
    return
  end

  local head = data:sub(1, head_index - 1)
  local completed = self._incompleted .. head

  self._incompleted = data:sub(head_index + 1)

  return completed
end

function OutputBuffer.pop(self)
  return self:append("\n")
end

return M
