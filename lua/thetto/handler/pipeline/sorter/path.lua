local M = {}

function M.apply(stage_ctx, items, _)
  local input = stage_ctx.input
  if #input <= 1 then
    return items
  end

  local inputs = vim
    .iter(vim.split(input:lower(), "%s"))
    :filter(function(text)
      return text ~= ""
    end)
    :totable()

  table.sort(items, function(item_a, item_b)
    local file_name_a = vim.fs.basename(item_a.path):lower()
    local file_name_b = vim.fs.basename(item_b.path):lower()
    for _, x in ipairs(inputs) do
      local match_a = file_name_a:match(x)
      local match_b = file_name_b:match(x)

      if match_a and not match_b then
        return true
      end
      if match_b and not match_a then
        return false
      end
    end
    return item_a.index > item_b.index
  end)

  return items
end

M.is_sorter = true
M.input_index = 1

return M
