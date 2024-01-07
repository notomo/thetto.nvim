local M = {}

function M.start(source, opts)
  return require("thetto2.command").start(source, opts)
end

function M.reload(bufnr)
  return require("thetto2.command").reload(bufnr)
end

function M.resume(opts)
  return require("thetto2.command").resume(opts)
end

function M.execute(item_action_groups, opts)
  return require("thetto2.command").execute(item_action_groups, opts)
end

function M.get()
  return require("thetto2.command").get()
end

function M.call_consumer(action_name, opts)
  return require("thetto2.command").call_consumer(action_name, opts)
end

function M.setup_store(name, opts)
  require("thetto2.command").setup_store(name, opts)
end

return M
