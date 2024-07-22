local M = {}

M.opts = { cmd = "messages" }

function M.collect(source_ctx)
  local outputs = vim.api.nvim_exec2(source_ctx.opts.cmd, { output = true }).output
  return vim
    .iter(vim.gsplit(outputs, "\n", true))
    :map(function(line)
      return {
        value = line,
      }
    end)
    :totable()
end

M.kind_name = "word"

return M
