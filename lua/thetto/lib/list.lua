local M = {}

M.unique = function(list)
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

M.group_by = function(list, make_key)
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

return M
