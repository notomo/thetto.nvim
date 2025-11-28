local M = {}

local driver = function(cmd, opts)
  opts.term = true
  vim.fn.jobstart(cmd, opts)
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

    local cmd = { "node", "--run", item.value }
    local opts = { cwd = vim.fs.dirname(item.path) }
    action_ctx.opts.driver(cmd, opts)
  end
end

function M.action_terminal(items, action_ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "execute", items, {
    driver = function(cmd, opts)
      vim.fn.jobstart(vim.opt.shell:get(), {
        cwd = opts.cwd,
        term = true,
      })
      local input = table.concat(cmd, " ") .. "\n"
      vim.api.nvim_put({ input }, "c", true, true)
    end,
  })
end

M.default_action = "execute"

return require("thetto.core.kind").extend(M, "file")
