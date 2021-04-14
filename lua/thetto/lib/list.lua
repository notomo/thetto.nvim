local M = {}

function M.unique(list)
  local hash = {}
  local new_list = {}
  for _, v in ipairs(list) do
    if not hash[v] then
      new_list[#new_list + 1] = v
      hash[v] = true
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
      table.insert(groups, {key, {element}})
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

return M
