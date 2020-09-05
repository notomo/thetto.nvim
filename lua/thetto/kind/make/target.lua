local M = {}

M.action_execute = function(_, items)
  for _, item in ipairs(items) do
    vim.api.nvim_command("tabedit")
    local cmd = {"make", "-f", item.path, item.value}
    vim.fn.termopen(cmd, {cwd = vim.fn.fnamemodify(item.path, ":h")})
  end
end

M.default_action = "execute"

return setmetatable(M, require("thetto/kind/file"))
