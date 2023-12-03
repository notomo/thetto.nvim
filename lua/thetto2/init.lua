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

function M.execute(opts)
  return require("thetto2.command").execute(opts)
end

function M.get()
  return require("thetto2.command").get()
end

return M
