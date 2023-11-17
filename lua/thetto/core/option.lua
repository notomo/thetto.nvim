local M = {}

local default_start_opts = {
  pipeline = function(items)
    return items
  end,
  consume = function(items)
    return items
  end,
  kind = {},
}
function M.new_start_opts(raw_opts)
  return vim.tbl_extend("force", default_start_opts, raw_opts or {})
end

return M
