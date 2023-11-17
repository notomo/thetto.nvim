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

function M.execute(opts)
  return require("thetto.command").execute(opts)
end

function M.get()
  return require("thetto.command").get()
end

return M
