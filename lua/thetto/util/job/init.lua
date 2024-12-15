local M = {}

local write_log = function(cmd)
  local log_dir = tostring(vim.fn.stdpath("log"))
  vim.fn.mkdir(log_dir, "p")

  local log_path = vim.fs.joinpath(log_dir, "thetto.log")
  local log_file = io.open(log_path, "a")
  if not log_file then
    error("could not open log file: " .. log_path)
  end
  local msg
  if type(cmd) == "table" then
    msg = table.concat(cmd, " ")
  else
    msg = cmd
  end
  log_file:write(("[%s] %s\n"):format(os.date(), msg))
  log_file:close()
end

function M.run(cmd, source_ctx, to_item, raw_opts)
  local default_opts = {
    to_outputs = function(output)
      return require("thetto.util.job.parse").output(output)
    end,
    stop_on_error = true,
    input = nil,
    cwd = source_ctx.cwd,
  }
  local opts = vim.tbl_extend("force", default_opts, raw_opts or {})

  return function(observer)
    write_log(cmd)

    local _, job = pcall(function()
      return vim.system(cmd, {
        text = true,
        cwd = opts.cwd,
        env = opts.env,
        stdin = opts.input,
      }, function(o)
        local code = o.code
        if opts.stop_on_error and code ~= 0 then
          return observer:error(o.stderr)
        end

        local out_or_err = code ~= 0 and o.stderr or o.stdout
        local items = vim
          .iter(opts.to_outputs(out_or_err))
          :map(function(output)
            local item = to_item(output, code)
            if not item then
              return
            end
            return item
          end)
          :totable()
        observer:next(items)
        observer:complete()
      end)
    end)
    if type(job) == "string" then
      local err = job
      return observer:error(err)
    end

    local cancel = function()
      job:kill(0)
    end
    return cancel
  end
end

function M.start(cmd, source_ctx, to_item, raw_opts)
  local default_opts = {
    to_outputs = function(data)
      return require("thetto.util.job.parse").output(data)
    end,
    input = nil,
    cwd = source_ctx.cwd,
  }
  local opts = vim.tbl_extend("force", default_opts, raw_opts or {})

  local to_items = function(outputs)
    return vim.iter(outputs):map(to_item):totable()
  end

  return function(observer)
    write_log(cmd)

    local _, job = pcall(function()
      return vim.system(cmd, {
        text = true,
        stdout = function(_, data)
          if not data then
            return
          end

          local outputs = opts.to_outputs(data)
          observer:next(to_items(outputs))
        end,
        cwd = opts.cwd,
        env = opts.env,
        stdin = opts.input,
      }, function(o)
        if o.code ~= 0 then
          return observer:error(o.stderr)
        end
        observer:complete()
      end)
    end)
    if type(job) == "string" then
      local err = job
      return observer:error(err)
    end

    local cancel = function()
      job:kill(0)
    end
    return cancel
  end
end

function M.execute(cmd, raw_opts)
  local default_opts = {
    text = true,
    stdout = function() end,
    stderr = function() end,
    on_exit = function() end,
  }
  local opts = vim.tbl_extend("force", default_opts, raw_opts or {})

  write_log(cmd)

  local _, result = pcall(function()
    return vim.system(cmd, opts, opts.on_exit)
  end)
  return result
end

function M.promise(cmd, raw_opts)
  local default_opts = {
    on_exit = function(output)
      vim.api.nvim_echo({ { output } }, true, {})
    end,
    is_err = function(code)
      return code ~= 0
    end,
  }
  local opts = vim.tbl_extend("force", default_opts, raw_opts or {})

  write_log(cmd)

  local promise, resolve, reject = require("thetto.vendor.promise").with_resolvers()
  local _, result = pcall(function()
    vim.system(
      cmd,
      { text = true },
      vim.schedule_wrap(function(o)
        if opts.is_err(o.code) then
          return reject(o.stderr)
        end
        local output = o.stdout
        opts.on_exit(output, o.code)
        return resolve(output)
      end)
    )
  end)
  if type(result) == "string" then
    local err = result
    reject(err)
  end

  return promise
end

return M
