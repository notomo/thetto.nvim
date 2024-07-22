local M = {}

function M.collect()
  return vim
    .iter(vim.fn.getcompletion("*", "environment"))
    :map(function(name)
      local value = ("%s=%s"):format(name, os.getenv(name):gsub("\n", "\\n"))
      return {
        value = value,
      }
    end)
    :totable()
end

M.kind_name = "word"

return M
