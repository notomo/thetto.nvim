local M = {}

function M.offset(row_offset)
  return function()
    return {
      row_offset = row_offset,
    }
  end
end

function M.top()
  return function()
    return {
      row_offset = 0,
    }
  end
end

function M.bottom()
  return function()
    return {
      row_offset = math.huge,
    }
  end
end

function M.search(f)
  return function(all_items)
    local row
    for i, item in ipairs(all_items) do
      if f(item) then
        row = i
        break
      end
    end
    return {
      row = row,
    }
  end
end

return M
