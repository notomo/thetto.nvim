local M = {}

function M.to(item, opts)
  return opts.to_field(item):lower()
end

M.opts = {
  to_field = function(item)
    return item.value
  end,
}

M.reversed = false

return M
