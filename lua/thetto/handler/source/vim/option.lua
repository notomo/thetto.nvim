local M = {}

function M.collect()
  return vim
    .iter(require("thetto.lib.completion").get("*", "option"))
    :skip(1) -- NOTE: ignore 'all'
    :map(function(name)
      local cmd = ("echo &%s"):format(name)
      local option_value = vim.api.nvim_exec2(cmd, { output = true }).output
      local value = ("%s=%s"):format(name, option_value)
      return {
        value = value,
        option = {
          name = name,
          value = option_value,
        },
      }
    end)
    :totable()
end

M.kind_name = "vim/option"

return M
