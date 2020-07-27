local M = {}

M.get_command = function(path, max_depth)
  return {
    "find",
    "-L",
    path,
    "-maxdepth",
    max_depth,
    "-type",
    "d",
    "-name",
    ".git",
    "-prune",
    "-o",
    "-type",
    "d",
    "-print",
  }
end

M.opts = {max_depth = 100}

M.collect = function(self, opts)
  return require("thetto/source/file/recursive").collect(self, opts)
end

M.kind_name = "directory"

return M
