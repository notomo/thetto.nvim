local M = {}

local Job = {}
Job.__index = Job

local close = function(handle)
  if handle:is_closing() then
    return
  end
  handle:close()
end

function Job._shutdown(self, code, signal)
  if self.on_interval then
    self.timer:stop()
  end
  if self.on_exit then
    self:on_exit(code, signal)
  end
  self:stop()
end

function Job.start(self)
  self.stdin = vim.loop.new_pipe(false)
  self.stdout = vim.loop.new_pipe(false)
  self.stderr = vim.loop.new_pipe(false)

  local opts = {args = self.args, stdio = {self.stdin, self.stdout, self.stderr}}

  self.handle, self.pid = vim.loop.spawn(self.command, opts, vim.schedule_wrap(function(code, signal)
    self:_shutdown(code, signal)
  end))

  self.stdout:read_start(vim.schedule_wrap(function(err, data)
    if data ~= nil then
      self._stdout_output = self._stdout_output .. data
      self.all_output = self.all_output .. data
    end
    if self.on_stdout then
      self:on_stdout(err, data)
    end
  end))

  self.stderr:read_start(vim.schedule_wrap(function(err, data)
    if data ~= nil then
      self._stderr_output = self._stderr_output .. data
      self.all_output = self.all_output .. data
    end
    if self.on_stderr then
      self:on_stderr(err, data)
    end
  end))

  if self.on_interval then
    self.timer = vim.loop.new_timer()
    self.timer:start(self.interval_ms, 100, vim.schedule_wrap(function()
      self:on_interval()
    end))
  end
end

function Job.stop(self)
  self.stdout:read_stop()
  self.stderr:read_stop()

  if self.on_interval then
    self.timer:stop()
  end

  close(self.stdin)
  close(self.stderr)
  close(self.stdout)
  close(self.handle)
end

function Job.parse_output(data)
  return vim.split(data, "\n", true)
end

function Job.get_stdout(self)
  local output = self.parse_output(self._stdout_output)
  if output[#output] == "" then
    table.remove(output, #output)
  end
  return output
end

local new = function(cmd_and_args, opts)
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
  job._stdout_output = ""
  job._stderr_output = ""
  job.all_output = ""

  job.on_interval = opts.on_interval
  job.interval_ms = opts.interval_ms or 1000

  return setmetatable(job, Job)
end

M.new = new

return M
