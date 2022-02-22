local M = {}

local StartArgs = {}
StartArgs.__index = StartArgs
M.StartArgs = StartArgs
StartArgs.default = {
  source_opts = {},
  action_opts = {},
  opts = {},
}
function StartArgs.new(raw_args)
  vim.validate({ raw_args = { raw_args, "table", true } })
  raw_args = raw_args or {}
  return vim.tbl_deep_extend("force", StartArgs.default, raw_args)
end

local ResumeExecuteArgs = {}
ResumeExecuteArgs.__index = ResumeExecuteArgs
M.ResumeExecuteArgs = ResumeExecuteArgs
ResumeExecuteArgs.default = {
  source_name = nil,
  action_name = "default",
  action_opts = {},
  opts = { offset = 0 },
}
function ResumeExecuteArgs.new(raw_args)
  vim.validate({ raw_args = { raw_args, "table", true } })
  raw_args = raw_args or {}
  return vim.tbl_deep_extend("force", ResumeExecuteArgs.default, raw_args)
end

local ExecuteArgs = {}
ExecuteArgs.__index = ExecuteArgs
M.ExecuteArgs = ExecuteArgs
ExecuteArgs.default = {
  fallback_actions = nil,
  action_opts = {},
}
function ExecuteArgs.new(action_name, raw_args)
  vim.validate({
    action_name = { action_name, "string", true },
    raw_args = { raw_args, "table", true },
  })
  raw_args = raw_args or {}
  local args = vim.tbl_deep_extend("force", ExecuteArgs.default, raw_args)
  args.action_name = action_name or "default"
  return args
end

return M
