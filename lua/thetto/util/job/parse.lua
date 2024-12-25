local M = {}

function M.output(output)
  return vim.split(output, "\n", { plain = true, trimempty = true })
end

function M.concat_func()
  local rest = ""
  return function(data)
    local joined = rest .. data
    local index = joined:reverse():find("\n") or 1
    local lines_str = joined:sub(0, -index)
    if index == 1 then
      rest = ""
    else
      rest = joined:sub(-index + 1)
    end
    return lines_str
  end
end

return M
