local Command = require("thetto.command").Command

local M = {}

function M.start(source_name, args)
  return Command.new("start", source_name, args)
end

function M.resume(source_name, args)
  return Command.new("resume", source_name, args)
end

function M.execute(action_name, args)
  return Command.new("execute", action_name, args)
end

function M.resume_execute(args)
  return Command.new("resume_execute", args)
end

function M.setup(config)
  return Command.new("setup", config)
end

function M.setup_store(name, opts)
  return Command.new("setup_store", name, opts)
end

return M
