local M = {}

function M.prepend(filter_name)
  return function(filters)
    local new_filters = { filter_name }
    vim.list_extend(new_filters, filters)
    return new_filters
  end
end

return M
