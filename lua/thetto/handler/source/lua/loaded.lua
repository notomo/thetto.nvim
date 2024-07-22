local M = {}

function M.collect()
  return vim
    .iter(package.loaded)
    :map(function(key)
      return {
        value = key,
      }
    end)
    :totable()
end

M.kind_name = "lua/package"

return M
