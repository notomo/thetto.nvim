local M = {}

function M.action_execute(_, items)
  for _, item in ipairs(items) do
    vim.cmd("tabedit")
    local cmd = {"make", "-f", item.path, item.value}
    vim.fn.termopen(cmd, {cwd = vim.fn.fnamemodify(item.path, ":h")})
  end
end

function M.action_dry_run(_, items)
  for _, item in ipairs(items) do
    vim.cmd("tabedit")
    local cmd = {"make", "-n", "-f", item.path, item.value}
    vim.fn.termopen(cmd, {cwd = vim.fn.fnamemodify(item.path, ":h")})
  end
end

M.default_action = "execute"

return setmetatable(M, require("thetto.handler.kind.file"))
