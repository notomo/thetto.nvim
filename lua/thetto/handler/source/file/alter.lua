local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")

local M = {}

function M.collect(source_ctx)
  local path = vim.api.nvim_buf_get_name(source_ctx.bufnr)
  for _, patterns in ipairs(source_ctx.opts.pattern_groups) do
    local items = M._to_items(source_ctx, patterns, path)
    if items ~= nil then
      return items
    end
  end
  return {}
end

function M._to_items(source_ctx, patterns, path)
  local index, matches
  for i, pattern in ipairs(patterns) do
    local m = M._match(pattern, path)
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

  local home = pathlib.home()
  local items = vim
    .iter(candidates)
    :map(function(pattern)
      local format_pattern, count = pattern:gsub("%%", "%%s")
      if count ~= #matches then
        return
      end

      local abs_path = format_pattern:format(unpack(matches))
      local value = abs_path:gsub(home, "~")
      if filelib.readable(abs_path) then
        return {
          value = value,
          path = abs_path,
        }
      elseif source_ctx.opts.allow_new then
        return {
          value = value,
          path = abs_path,
          kind_name = "file/new",
        }
      end
    end)
    :totable()

  if #items == 0 then
    return nil
  end

  return items
end

function M._match(pattern, path)
  local parts = vim.split(pattern, "%", { plain = true })
  parts = vim
    .iter(parts)
    :filter(function(part)
      return part ~= ""
    end)
    :totable()

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

M.opts = { pattern_groups = {}, allow_new = false }

M.consumer_opts = {
  ui = { insert = false },
}

M.kind_name = "file"

return M
