local M = vim.deepcopy(require("thetto.handler.kind.git.status"))

return require("thetto.core.kind").extend(M, "file")
