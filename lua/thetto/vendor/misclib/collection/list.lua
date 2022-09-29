local M = {}

function M.unique(list, make_key)
  make_key = make_key or function(v)
    return v
  end
  local hash = {}
  local new_list = {}
  for _, v in ipairs(list) do
    local key = make_key(v)
    if not hash[key] then
      new_list[#new_list + 1] = v
      hash[key] = true
    end
  end
  return new_list
end

function M.group_by_adjacent(list, make_key)
  local prev = nil
  local groups = {}
  for _, element in ipairs(list) do
    local key = make_key(element)
    if key == prev then
      table.insert(groups[#groups][2], element)
    else
      table.insert(groups, { key, { element } })
    end
    prev = key
  end
  return groups
end

function M.fill(list, length, element)
  local new_list = vim.deepcopy(list)
  for _ = #list + 1, length, 1 do
    table.insert(new_list, element)
  end
  return new_list
end

return M
