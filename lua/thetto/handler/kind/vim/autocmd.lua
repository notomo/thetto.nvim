local M = {}

local anonymous_autocmd_kind = require("thetto.handler.kind.vim.anonymous_autocmd")
local file_kind = require("thetto.handler.kind.file")

return require("thetto.core.kind").extend(M, anonymous_autocmd_kind, file_kind)
