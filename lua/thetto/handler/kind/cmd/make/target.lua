local M = {}

local driver = function(cmd, opts)
  vim.fn.termopen(cmd, opts)
end

M.opts = {}
M.opts.execute = { driver = driver }

function M.action_execute(items, action_ctx)
  for _, item in ipairs(items) do
    vim.cmd.tabedit()
    local cmd = { "make", "-f", item.path, item.value }
    local opts = { cwd = vim.fn.fnamemodify(item.path, ":h") }
    action_ctx.opts.driver(cmd, opts)
  end
end

function M.action_dry_run(items, action_ctx)
  for _, item in ipairs(items) do
    vim.cmd.tabedit()
    local cmd = { "make", "-n", "-f", item.path, item.value }
    local opts = { cwd = vim.fn.fnamemodify(item.path, ":h") }
    action_ctx.opts.execute.driver(cmd, opts) --TODO
  end
end

M.default_action = "execute"

return require("thetto.core.kind").extend(M, "file")
