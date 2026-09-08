local M = {}

--- @async
--- @param opts table
--- @return string?
function M.await(opts)
  local input = vim.async.await(2, vim.ui.input, opts) --[[@as string?]]
  return input
end

return M
