local M = {}

function M.start(source_name, args)
  return require("thetto.command").start(source_name, args)
end

function M.reload()
  return require("thetto.command").reload()
end

function M.resume(source_name, args)
  return require("thetto.command").resume(source_name, args)
end

function M.execute(action_name, args)
  return require("thetto.command").execute(action_name, args)
end

function M.resume_execute(args)
  return require("thetto.command").resume_execute(args)
end

function M.setup(config)
  return require("thetto.command").setup(config)
end

function M.setup_store(name, opts)
  return require("thetto.command").setup_store(name, opts)
end

return M
