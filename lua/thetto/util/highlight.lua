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

local highlight_opts = {
  priority = vim.hl.priorities.user - 1,
}

function M.columns(hl_columns)
  local columns = vim
    .iter(hl_columns)
    :map(function(hl_column)
      return to_column(hl_column)
    end)
    :totable()
  return function(decorator, items, first_line, _)
    for i, item in ipairs(items) do
      vim.iter(columns):each(function(column)
        local hl_group = column.to_hl_group(item)
        if not hl_group then
          return
        end

        local start_column = column.to_start(item)
        local end_column = column.to_end(item)
        decorator:highlight(hl_group, first_line + i - 1, start_column, end_column, highlight_opts)
      end)
    end
  end
end

return M
