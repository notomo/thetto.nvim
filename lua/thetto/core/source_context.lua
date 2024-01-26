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

--- @class ThettoSourceContext
--- @field cwd string
--- @field bufnr integer
--- @field window_id integer
--- @field pattern string
--- @field opts table
--- @field store_to_restart table?

--- @return ThettoSourceContext
function M.new(source, source_bufnr, source_window_id, source_input_pattern, store_to_restart)
  local pattern = source_input_pattern
  if not pattern and source.get_pattern then
    pattern = source.get_pattern()
  end

  return {
    cwd = resolve_cwd(source.cwd),
    bufnr = source_bufnr,
    window_id = source_window_id,
    pattern = pattern or "",
    opts = source.opts or {},
    store_to_restart = store_to_restart,
  }
end

return M
