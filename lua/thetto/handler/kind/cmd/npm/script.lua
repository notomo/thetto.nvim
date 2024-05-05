local M = {}

local driver = function(cmd, opts)
  vim.fn.termopen(cmd, opts)
end

M.opts = {}

M.opts.execute = {
  driver = driver,
  open = function()
    require("thetto.lib.buffer").open_scratch_tab()
  end,
}
function M.action_execute(items, action_ctx)
  for _, item in ipairs(items) do
    action_ctx.opts.open()

    local cmd = { "npm", "run", item.value }
    local opts = { cwd = vim.fn.fnamemodify(item.path, ":h") }
    action_ctx.opts.driver(cmd, opts)
  end
end

M.default_action = "execute"

return require("thetto.core.kind").extend(M, "file")
