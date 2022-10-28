local vim = vim

local M = {}

local Job = {}
Job.__index = Job

local close = function(handle)
  if handle == nil or handle:is_closing() then
    return
  end
  handle:close()
end

function Job._shutdown(self, code, signal)
  self:stop()
  if self.on_exit and not self.discarded then
    self:on_exit(code, signal)
  end
end

function Job.is_running(self)
  return self.handle ~= nil and self.handle:is_active()
end

local _adjust
if vim.loop.os_uname().version:match("Windows") then
  _adjust = function(data)
    return data:gsub("\r", "")
  end
else
  _adjust = function(data)
    return data
  end
end

function Job.start(self)
  self.stdin = vim.loop.new_pipe(false)
  self.stdout = vim.loop.new_pipe(false)
  self.stderr = vim.loop.new_pipe(false)

  local log_dir = vim.fn.stdpath("log")
  vim.fn.mkdir(log_dir, "p")

  local log_path = require("thetto.lib.path").join(log_dir, "thetto.log")
  local log_file = io.open(log_path, "a")
  if not log_file then
    return "could not open log file: " .. log_path
  end
  local msg = self.command .. " " .. table.concat(self.args, " ")
  log_file:write(("[%s] %s\n"):format(os.date(), msg))
  log_file:close()

  local opts = {
    args = self.args,
    stdio = { self.stdin, self.stdout, self.stderr },
    cwd = self.cwd,
    env = self.env,
    detach = self.detach,
  }

  self.handle, self.pid = vim.loop.spawn(
    self.command,
    opts,
    vim.schedule_wrap(function(code, signal)
      self:_shutdown(code, signal)
    end)
  )
  if type(self.pid) ~= "number" then
    return self.pid .. ": " .. self.command
  end

  self.stdout:read_start(vim.schedule_wrap(function(err, data)
    if self.stdout_buffered and data ~= nil then
      local adjusted = _adjust(data)
      self.stdout_output = self.stdout_output .. adjusted
      self.all_output = self.all_output .. adjusted
    end
    if self.on_stdout and not self.discarded then
      self:on_stdout(err, data)
    end
  end))

  self.stderr:read_start(vim.schedule_wrap(function(err, data)
    if self.stderr_buffered and data ~= nil then
      local adjusted = _adjust(data)
      self.stderr_output = self.stderr_output .. adjusted
      self.all_output = self.all_output .. adjusted
    end
    if self.on_stderr and not self.discarded then
      self:on_stderr(err, data)
    end
  end))
end

function Job.discard(self)
  self.discarded = true
  self:stop()
end

function Job.stop(self)
  self.stdout:read_stop()
  self.stderr:read_stop()

  close(self.stdin)
  close(self.stderr)
  close(self.stdout)
  close(self.handle)
end

function M.parse_output(data)
  if data == nil then
    return {}
  end
  data = _adjust(data)
  return vim.split(data, "\n", true)
end

function Job.get_stdout(self)
  local output = M.parse_output(self.stdout_output)
  if output[#output] == "" then
    table.remove(output, #output)
  end
  return output
end

function Job.get_joined_stdout(self)
  return table.concat(self:get_stdout(), "")
end

function Job.get_output(self)
  local output = M.parse_output(self.all_output)
  if output[#output] == "" then
    table.remove(output, #output)
  end
  return output
end

function M.new(cmd_and_args, opts)
  local job = {}

  local command = table.remove(cmd_and_args, 1)
  local args = cmd_and_args
  job.command = command
  job.args = args
  job.cwd = opts.cwd
  job.env = opts.env
  job.detach = opts.detach

  job.on_stdout = opts.on_stdout
  job.on_stderr = opts.on_stderr
  job.on_exit = opts.on_exit

  job.stdout_output = ""
  job.stdout_buffered = true
  if opts.stdout_buffered ~= nil then
    job.stdout_buffered = opts.stdout_buffered
  end

  job.stderr_output = ""
  job.stderr_buffered = true
  if opts.stderr_buffered ~= nil then
    job.stderr_buffered = opts.stderr_buffered
  end

  job.all_output = ""
  job.discarded = false

  return setmetatable(job, Job)
end

function M.print_stderr(_, _, data)
  if data == nil or data == "" then
    return
  end
  vim.api.nvim_err_write(data .. "\n")
end

function M.print_stdout(self)
  if self.stdout_output == "" then
    return
  end
  local output = table.concat(self:get_stdout(), "\n")
  vim.api.nvim_out_write(output .. "\n")
end

return M
