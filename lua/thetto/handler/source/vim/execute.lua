local M = {}

M.opts = { cmd = "messages" }

function M.collect(source_ctx)
  local items = {}
  local outputs = vim.api.nvim_exec(source_ctx.opts.cmd, true)
  for line in vim.gsplit(outputs, "\n", true) do
    table.insert(items, { value = line })
  end
  return items
end

M.kind_name = "word"

return M
