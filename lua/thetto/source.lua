local util = require("thetto/util")
local jobs = require("thetto/job")
local highlight = require("thetto/highlight")

local M = {}

local create = function(source_name, source_opts)
  local origin = util.find_source(source_name)
  if origin == nil then
    return nil, "not found source: " .. source_name
  end
  origin.__index = origin

  local source = {}
  source.name = source_name
  source.opts = source_opts

  source.jobs = jobs
  source.highlights = highlight

  return setmetatable(source, origin), nil
end

M.create = create

return M
