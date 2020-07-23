local util = require("thetto/util")
local jobs = require("thetto/job")
local highlight = require("thetto/highlight")

local M = {}

M.create = function(source_name, source_opts)
  local origin = util.find_source(source_name)
  if origin == nil then
    return nil, "not found source: " .. source_name
  end
  origin.__index = origin

  local source = {}
  source.name = source_name
  source.opts = vim.tbl_extend("force", origin.opts or {}, source_opts)

  source.jobs = jobs
  source.highlights = highlight

  return setmetatable(source, origin), nil
end

return M
