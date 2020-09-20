local M = {}

M.collect = function(self)
  local path = vim.fn.expand("%:p")
  for _, patterns in ipairs(self.opts.pattern_groups) do
    local items = self:_to_items(patterns, path)
    if items ~= nil then
      return items
    end
  end
  return {}
end

M._to_items = function(self, patterns, path)
  local index, matches
  for i, pattern in ipairs(patterns) do
    local m = self._match(pattern, path)
    if m ~= nil then
      index = i
      matches = m
      break
    end
  end
  if index == nil then
    return nil
  end

  local candidates = vim.deepcopy(patterns)
  table.remove(candidates, index)

  local items = {}
  local home = os.getenv("HOME")
  for _, pattern in ipairs(candidates) do
    local format_pattern, count = pattern:gsub("%%", "%%s")
    if count ~= #matches then
      goto continue
    end

    local abs_path = format_pattern:format(unpack(matches))
    local value = abs_path:gsub(home, "~")
    if self.filelib.readable(abs_path) then
      table.insert(items, {value = value, path = abs_path})
    elseif self.opts.allow_new then
      table.insert(items, {value = value, path = abs_path, kind = "new_file"})
    end

    ::continue::
  end
  if #items == 0 then
    return nil
  end

  return items
end

M._match = function(pattern, path)
  local parts = vim.split(pattern, "%", true)
  parts = vim.tbl_filter(function(part)
    return part ~= ""
  end, parts)

  if #parts == 0 then
    return nil
  end

  local index = 1
  local matches = {}
  for _, part in ipairs(parts) do
    local s, e = path:find(part, index, true)
    if s == nil then
      return nil
    end
    if index < s then
      local match = path:sub(index, s - 1)
      table.insert(matches, match)
    end
    index = e + 1
  end

  return matches
end

M.opts = {pattern_groups = {}, allow_new = false}

M.kind_name = "file"

return M
