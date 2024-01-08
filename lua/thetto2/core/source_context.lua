local M = {}

local default_behaviors = {
  cwd = function()
    return "."
  end,
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

function M.new(source, source_bufnr, source_input)
  source_input = source_input or {
    pattern = nil,
    is_interactive = false,
  }

  local ctx = vim.tbl_extend("keep", source.behaviors or {}, default_behaviors)
  ctx.cwd = resolve_cwd(ctx.cwd)
  ctx.bufnr = source_bufnr
  ctx.pattern = source_input.pattern
  ctx.interactive = source_input.is_interactive
  ctx.opts = source.opts
  return ctx
end

return M
