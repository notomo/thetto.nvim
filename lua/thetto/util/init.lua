local M = {}
return setmetatable(M, {
  __index = function(_, key)
    return require("thetto.util." .. key)
  end,
})
