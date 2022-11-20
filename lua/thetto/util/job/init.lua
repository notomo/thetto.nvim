local joblib = require("thetto.vendor.misclib.job")

local M = {}

local job_start = function(cmd, opts)
  local log_dir = vim.fn.stdpath("log")
  vim.fn.mkdir(log_dir, "p")

  local log_path = require("thetto.lib.path").join(log_dir, "thetto.log")
  local log_file = io.open(log_path, "a")
  if not log_file then
    return nil, "could not open log file: " .. log_path
  end
  local msg = table.concat(cmd, " ")
  log_file:write(("[%s] %s\n"):format(os.date(), msg))
  log_file:close()

  return joblib.start(cmd, opts)
end

local start = function(observer, cmd, opts, input)
  local job, err = job_start(cmd, opts)
  if err then
    return observer:error(err)
  end

  local cancel = function()
    job:stop()
  end
  if not input then
    return cancel
  end

  job:input(input)
  job:close_stdin()

  return cancel
end

function M.run(cmd, source_ctx, to_item, opts)
  local default_opts = {
    to_outputs = function(output)
      return require("thetto.util.job.parse").output(output)
    end,
    stop_on_error = true,
    input = nil,
    cwd = source_ctx.cwd,
    stdout_buffered = true,
    stderr_buffered = true,
  }
  opts = vim.tbl_extend("force", default_opts, opts or {})

  if opts.env and vim.tbl_isempty(opts.env) then
    opts.env = nil
  end

  local stdout = require("thetto.vendor.misclib.job.output").new()
  local stderr = require("thetto.vendor.misclib.job.output").new()
  return function(observer)
    return start(observer, cmd, {
      on_exit = function(_, code)
        if opts.stop_on_error and code ~= 0 then
          return observer:error(stderr:str())
        end

        local items = {}
        local out_or_err = code ~= 0 and stderr:str() or stdout:str()
        for _, output in ipairs(opts.to_outputs(out_or_err)) do
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
      on_stdout = stdout:collector(),
      on_stderr = stderr:collector(),
      env = opts.env,
    }, opts.input)
  end
end

function M.start(cmd, source_ctx, to_item, opts)
  local default_opts = {
    to_outputs = function(data)
      return require("thetto.util.job.parse").output(data)
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

  local output_buffer = require("thetto.vendor.misclib.job.output").new_buffer()
  local stderr = require("thetto.vendor.misclib.job.output").new()
  return function(observer)
    return start(observer, cmd, {
      on_stdout = function(_, data)
        if #data == 1 and data[1] == "" then
          local str = output_buffer:pop()
          local outputs = opts.to_outputs(str)
          if outputs[#outputs] == "" then
            table.remove(outputs, #outputs)
          end
          local items = to_items(outputs)
          observer:next(items)
          return
        end

        local str = output_buffer:append(data)
        if not str then
          return
        end

        local outputs = opts.to_outputs(str)
        observer:next(to_items(outputs))
      end,
      on_exit = function(_, code)
        if code ~= 0 then
          return observer:error(stderr:str())
        end
        observer:complete()
      end,
      cwd = opts.cwd,
      stdout_buffered = false,
      stderr_buffered = true,
      on_stderr = stderr:collector(),
      env = opts.env,
    }, opts.input)
  end
end

function M.execute(cmd, opts)
  local stdout = require("thetto.vendor.misclib.job.output").new()
  local default_opts = {
    on_exit = function()
      vim.api.nvim_echo({ { stdout:str() } }, true, {})
    end,
    on_stderr = function(_, data)
      if #data == 1 and data[1] == "" then
        return
      end
      vim.api.nvim_err_write(table.concat(data, "\n") .. "\n")
    end,
    on_stdout = stdout:collector(),
  }
  opts = vim.tbl_extend("force", default_opts, opts or {})
  return job_start(cmd, opts)
end

function M.promise(cmd, opts)
  opts = opts or {}
  opts.is_err = opts.is_err or function(code)
    return code ~= 0
  end

  local stdout = require("thetto.vendor.misclib.job.output").new()
  local stderr = require("thetto.vendor.misclib.job.output").new()
  return require("thetto.vendor.promise").new(function(resolve, reject)
    local default_opts = {
      stderr_buffered = true,
      stdout_buffered = true,
      on_stdout = stdout:collector(),
      on_stderr = stderr:collector(),
    }
    local on_exit = opts.on_exit or function(output)
      vim.api.nvim_echo({ { output } }, true, {})
    end
    opts = vim.tbl_extend("force", default_opts, opts)
    opts.on_exit = function(_, code)
      if opts.is_err(code) then
        return reject(stderr:str())
      end
      local output = stdout:str()
      on_exit(output, code)
      return resolve(output)
    end
    if opts.env and vim.tbl_isempty(opts.env) then
      opts.env = nil
    end

    local _, err = job_start(cmd, opts)
    if err ~= nil then
      return reject(err)
    end
  end)
end

return M
