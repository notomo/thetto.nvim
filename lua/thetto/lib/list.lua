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

function M.group_by(list, make_key)
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

function M.remove(list, value)
  local idx
  for i, v in ipairs(list) do
    if v == value then
      idx = i
      break
    end
  end

  if idx ~= nil then
    table.remove(list, idx)
    return true
  end
  return false
end

function M.fill(list, length, str)
  local new_list = vim.deepcopy(list)
  for _ = #list + 1, length, 1 do
    table.insert(new_list, str)
  end
  return new_list
end

return M
