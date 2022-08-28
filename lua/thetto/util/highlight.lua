local M = {}
M.__index = M

local start_column_func = function(hl_column)
  if hl_column.start_column then
    return function()
      return hl_column.start_column
    end
  end
  if type(hl_column.start_key) == "function" then
    return hl_column.start_key
  end
  if not hl_column.start_key then
    return function()
      return 0
    end
  end
  return function(item)
    return item.column_offsets[hl_column.start_key]
  end
end

local end_column_func = function(hl_column)
  if hl_column.end_column then
    return function()
      return hl_column.end_column
    end
  end
  if type(hl_column.end_key) == "function" then
    return hl_column.end_key
  end
  if not hl_column.end_key then
    return function()
      return -1
    end
  end
  return function(item)
    return item.column_offsets[hl_column.end_key]
  end
end

local hl_group_func = function(hl_column)
  if type(hl_column.group) == "function" then
    return hl_column.group
  end
  if not hl_column.filter then
    return function()
      return hl_column.group
    end
  end
  return function(item)
    return hl_column.filter(item) and hl_column.group or hl_column.else_group
  end
end

local to_column = function(hl_column)
  return {
    to_hl_group = hl_group_func(hl_column),
    to_start = start_column_func(hl_column),
    to_end = end_column_func(hl_column),
  }
end

function M.columns(hl_columns)
  local columns = vim.tbl_map(function(hl_column)
    return to_column(hl_column)
  end, hl_columns)
  return function(highlighter, items, first_line, _)
    for i, item in ipairs(items) do
      for _, column in ipairs(columns) do
        local hl_group = column.to_hl_group(item)
        if not hl_group then
          goto continue
        end

        local start_column = column.to_start(item)
        local end_column = column.to_end(item)
        highlighter:add(hl_group, first_line + i - 1, start_column, end_column)

        ::continue::
      end
    end
  end
end

return M
