local M = {}

function M.offset(row_offset)
  return function()
    return {
      row_offset = row_offset,
    }
  end
end

function M.no()
  return function()
    return {
      row_offset = 0,
    }
  end
end

return M
