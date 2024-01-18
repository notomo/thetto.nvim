local M = {}

function M.to(item, opts)
  local v = opts.to_field(item)
  if v then
    return 1
  end
  return 0
end

M.opts = {
  to_field = function(item)
    return item.value
  end,
}

M.reversed = false

return M
