local M = {}

function M.start(source, opts)
  return require("thetto.command").start(source, opts)
end

function M.reload(bufnr)
  return require("thetto.command").reload(bufnr)
end

function M.resume(opts)
  return require("thetto.command").resume(opts)
end

function M.execute(item_action_groups, opts)
  return require("thetto.command").execute(item_action_groups, opts)
end

function M.get()
  return require("thetto.command").get()
end

function M.call_consumer(action_name, opts)
  return require("thetto.command").call_consumer(action_name, opts)
end

function M.setup_store(name, opts)
  require("thetto.command").setup_store(name, opts)
end

function M.register_source(source_name, source)
  require("thetto.core.source").register(source_name, source)
end

function M.register_kind(kind_name, kind)
  require("thetto.core.kind").register(kind_name, kind)
end

function M.set_default(setting)
  require("thetto.core.source").setup(setting.sources)
  require("thetto.core.kind").setup(setting.kinds)
end

return M
