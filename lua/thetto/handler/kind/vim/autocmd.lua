local M = {}

local anonymous_autocmd_kind = require("thetto.handler.kind.vim.anonymous_autocmd")
local file_kind = require("thetto.handler.kind.file")
return setmetatable(M, {
  __index = function(_, k)
    return rawget(M, k) or anonymous_autocmd_kind[k] or file_kind[k]
  end,
})
