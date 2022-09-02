local jobs = require("thetto.lib.job")

local M = {}

local start = function(observer, job, input)
  local err = job:start()
  if err then
    return observer:error(err)
  end

  local cancel = function()
    job:stop()
  end

  if not input then
    return cancel
  end
  job.stdin:write(input, function()
    if job.stdin:is_closing() then
      return
    end
    job.stdin:close()
  end)

  return cancel
end

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

    return start(observer, job, opts.input)
  end
end

function M.start(cmd, source_ctx, to_item, opts)
  local default_opts = {
    to_outputs = function(data)
      return jobs.parse_output(data)
    end,
    input = nil,
    cwd = source_ctx.cwd,
  }
  opts = vim.tbl_extend("force", default_opts, opts or {})

  local to_items = function(outputs)
    local items = {}
    for _, output in ipairs(outputs) do
      local item = to_item(output)
      if not item then
        goto continue
      end
      table.insert(items, item)
      ::continue::
    end
    return items
  end

  local output_buffer = require("thetto.util.job.output_buffer").new()
  return function(observer)
    local job = jobs.new(cmd, {
      on_stdout = function(_, _, data)
        if not data then
          local str = output_buffer:pop()
          local outputs = opts.to_outputs(str)
          if outputs[#outputs] == "" then
            table.remove(outputs, #outputs)
          end
          local items = to_items(outputs)
          observer:next(items)
          observer:complete()
          return
        end

        local str = output_buffer:append(data)
        if not str then
          return
        end

        local outputs = opts.to_outputs(str)
        observer:next(to_items(outputs))
      end,
      on_exit = function(self, code)
        if code ~= 0 then
          return observer:error(self.stderr_output)
        end
      end,
      cwd = opts.cwd,
      stdout_buffered = false,
      stderr_buffered = true,
    })

    return start(observer, job, opts.input)
  end
end

function M.execute(cmd, opts)
  local default_opts = {
    on_exit = jobs.print_stdout,
    on_stderr = jobs.print_stderr,
  }
  opts = vim.tbl_extend("force", default_opts, opts or {})

  local job = jobs.new(cmd, opts)
  local err = job:start()
  if err ~= nil then
    return nil, err
  end
  return job, nil
end

return M
