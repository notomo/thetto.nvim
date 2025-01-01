local M = {}

local driver = function(cmd, opts)
  opts.term = true
  vim.fn.jobstart(cmd, opts)
end

M.opts = {}
M.opts.execute = {
  driver = driver,
  args = { "-f" },
  open = function()
    require("thetto.lib.buffer").open_scratch_tab()
  end,
}

function M.action_execute(items, action_ctx)
  for _, item in ipairs(items) do
    action_ctx.opts.open()

    local cmd = { "make" }
    vim.list_extend(cmd, action_ctx.opts.args)

    local path = item.included_from or item.path
    vim.list_extend(cmd, { path })
    if item.value ~= "" then
      table.insert(cmd, item.value)
    end

    local opts = { cwd = vim.fs.dirname(path) }
    action_ctx.opts.driver(cmd, opts)
  end
end

function M.action_dry_run(items, action_ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "execute", items, {
    args = { "-n", "-f" },
  })
end

M.default_action = "execute"

return require("thetto.core.kind").extend(M, "file")
