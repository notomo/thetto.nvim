local M = {}

function M.promise(opts)
  local promise, resolve = require("thetto.vendor.promise").with_resolvers()
  vim.ui.input(opts, function(input)
    resolve(input)
  end)
  return promise
end

return M
