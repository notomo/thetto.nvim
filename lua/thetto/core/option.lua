local M = {}

local default_start_opts = {
  pipeline_stages_factory = require("thetto.util.pipeline").default(),
  consumer_factory = require("thetto.util.consumer").ui(),
  item_cursor_factory = require("thetto.util.item_cursor").top(),
  actions = {},
  source_bufnr = 0,
}
function M.new_start_opts(raw_opts)
  local opts = vim.tbl_extend("force", default_start_opts, raw_opts or {})
  if opts.source_bufnr == 0 then
    opts.source_bufnr = vim.api.nvim_get_current_buf()
  end

  local raw_item_cursor_factory = opts.item_cursor_factory
  opts.item_cursor_factory = function(all_items)
    return require("thetto.core.item_cursor").new(raw_item_cursor_factory(all_items))
  end

  return opts
end

local default_execute_opts = {
  quit = true,
}
function M.new_execute_opts(raw_opts)
  return vim.tbl_extend("force", default_execute_opts, raw_opts or {})
end

local default_resume_opts = {
  consumer_factory = require("thetto.util.consumer").ui(),
  item_cursor_factory = require("thetto.util.item_cursor").top(),
  offset = 0,
}
function M.new_resume_opts(raw_opts)
  local opts = vim.tbl_extend("force", default_resume_opts, raw_opts or {})

  local raw_item_cursor_factory = opts.item_cursor_factory
  opts.item_cursor_factory = function(all_items)
    return require("thetto.core.item_cursor").new(raw_item_cursor_factory(all_items))
  end

  return opts
end

return M
