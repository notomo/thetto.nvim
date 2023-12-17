local M = {}

function M.escape(path)
  return ([[`='%s'`]]):format(path:gsub("'", "''"))
end

function M.lcd(path)
  vim.cmd.lcd({ args = { M.escape(path) }, mods = { silent = true } })
end

return M
