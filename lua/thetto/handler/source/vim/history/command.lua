local M = {}

function M.collect()
  return vim
    .iter(vim.fn.range(vim.fn.histnr("cmd"), 1, -1))
    :map(function(i)
      local history = vim.fn.histget("cmd", i)
      if history == "" then
        return nil
      end
      return {
        value = history,
      }
    end)
    :totable()
end

M.kind_name = "vim/command"

return M
