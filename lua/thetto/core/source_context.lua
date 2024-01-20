local M = {}

local resolve_cwd = function(cwd)
  cwd = cwd or function()
    return "."
  end

  if type(cwd) == "function" then
    cwd = cwd()
  end
  cwd = vim.fn.expand(cwd)
  if cwd == "." then
    cwd = vim.fn.fnamemodify(".", ":p")
  end
  if cwd ~= "/" and vim.endswith(cwd, "/") then
    cwd = cwd:sub(1, #cwd - 1)
  end
  return cwd
end

function M.new(source, source_bufnr, source_input_pattern)
  local pattern = source_input_pattern
  if not pattern and source.get_pattern then
    pattern = source.get_pattern()
  end

  return {
    cwd = resolve_cwd(source.cwd),
    bufnr = source_bufnr,
    pattern = pattern or "",
    opts = source.opts,
  }
end

return M
