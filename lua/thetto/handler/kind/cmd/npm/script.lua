local M = {}

function M.action_execute(_, items)
  for _, item in ipairs(items) do
    vim.cmd("tabedit")
    local cmd = { "npm", "run", item.value }
    vim.fn.termopen(cmd, { cwd = vim.fn.fnamemodify(item.path, ":h") })
  end
end

M.default_action = "execute"

return require("thetto.core.kind").extend(M, "file")
