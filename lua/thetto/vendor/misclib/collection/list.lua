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

function M.group_by(list, make_key)
  local new_list = {}
  local indicies = {}
  for _, element in ipairs(list) do
    local key = make_key(element)

    local index = indicies[key] or (vim.tbl_count(indicies) + 1)
    indicies[key] = index

    local group = new_list[index] or { key, {} }
    table.insert(group[2], element)
    new_list[index] = group
  end
  return new_list
end

function M.fill(list, length, element)
  local new_list = vim.deepcopy(list)
  for _ = #list + 1, length, 1 do
    table.insert(new_list, element)
  end
  return new_list
end

function M.join_by(list, separator)
  if #list == 0 then
    return vim.iter(list):totable()
  end
  local new_list = {}
  for e in vim.iter(list):skipback(1) do
    table.insert(new_list, e)
    table.insert(new_list, separator)
  end
  table.insert(new_list, list[#list])
  return new_list
end

return M
