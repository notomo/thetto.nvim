local M = {}

function M.promise(opts)
  return require("thetto.vendor.promise").new(function(resolve)
    vim.ui.input(opts, function(input)
      resolve(input)
    end)
  end)
end

return M
