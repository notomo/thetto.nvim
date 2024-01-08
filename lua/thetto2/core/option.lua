local M = {}

local default_start_opts = {
  pipeline_stages_factory = require("thetto2.util.pipeline").default(),
  consumer_factory = require("thetto2.util.consumer").ui(),
  item_cursor_factory = require("thetto2.util.item_cursor").no(),
  actions = {},
}
function M.new_start_opts(raw_opts)
  return vim.tbl_extend("force", default_start_opts, raw_opts or {})
end

local default_execute_opts = {
  quit = true,
}
function M.new_execute_opts(raw_opts)
  return vim.tbl_extend("force", default_execute_opts, raw_opts or {})
end

local default_resume_opts = {
  consumer_factory = require("thetto2.util.consumer").ui(),
  item_cursor_factory = require("thetto2.util.item_cursor").no(),
  offset = 0,
}
function M.new_resume_opts(raw_opts)
  return vim.tbl_extend("force", default_resume_opts, raw_opts or {})
end

return M
