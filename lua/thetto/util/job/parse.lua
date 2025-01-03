local M = {}

function M.output(output)
  return vim.split(output, "\n", { plain = true, trimempty = true })
end

function M.concat_func()
  local incomplete = ""
  return function(data)
    if data == "" then
      local all = incomplete
      incomplete = ""
      return all
    end

    local joined = incomplete .. data
    local newline_index = joined:reverse():find("\n") or 0

    local completed = joined:sub(0, -newline_index)
    if newline_index == 1 then
      incomplete = ""
    else
      incomplete = joined:sub(-newline_index + 1)
    end
    return completed
  end
end

return M
