local M = {}

local default = {
  cwd = function()
    return "."
  end,
  opts = {},
}

local resolve_cwd = function(cwd)
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

function M.new(source)
  local tbl = vim.tbl_extend("keep", source, default)
  return {
    cwd = resolve_cwd(tbl.cwd),
    opts = tbl.opts,
  }
end

return M
